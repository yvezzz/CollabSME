from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


def apply_search_and_ordering(queryset, request, search_fields):
    search = request.query_params.get('search')
    if search:
        q = Q()
        for field in search_fields:
            q |= Q(**{f'{field}__icontains': search})
        queryset = queryset.filter(q)

    ordering = request.query_params.get('ordering', '-created_at')
    if ordering.lstrip('-') not in {f.split('__')[0] for f in search_fields} | {'created_at', 'updated_at', 'title', 'status', 'priority', 'order'}:
        ordering = '-created_at'
    queryset = queryset.order_by(ordering)

    return queryset

from activity.models import ActivityLog
from authentication.models import User
from .models import Project, ProjectMember, Task, ChecklistItem, Comment, Attachment
from .serializers import (
    ProjectSerializer,
    ProjectMemberSerializer,
    TaskSerializer,
    TaskStatusSerializer,
    TaskReorderSerializer,
    ChecklistItemSerializer,
    CommentSerializer,
    AttachmentSerializer,
    ProjectStatsSerializer,
)


def get_project_member(user, project):
    try:
        return ProjectMember.objects.get(project=project, user=user)
    except ProjectMember.DoesNotExist:
        return None


def require_project_role(project, user, allowed_roles):
    member = get_project_member(user, project)
    if not member or member.role not in allowed_roles:
        return False
    return True


# ─── Project CRUD ──────────────────────────────────────────────────

@api_view(['GET', 'POST'])
def project_list(request):
    if request.method == 'GET':
        projects = Project.objects.filter(company=request.user.company)
        status_filter = request.query_params.get('status')
        if status_filter:
            projects = projects.filter(status=status_filter)
        projects = apply_search_and_ordering(projects, request, ['title', 'description', 'key'])
        projects = projects.prefetch_related('members', 'tasks')

        paginator = PageNumberPagination()
        paginator.page_size = 20
        result_page = paginator.paginate_queryset(projects, request)
        serializer = ProjectSerializer(result_page, many=True)
        return paginator.get_paginated_response(serializer.data)

    if request.method == 'POST':
        serializer = ProjectSerializer(data=request.data)
        if serializer.is_valid():
            project = serializer.save(
                company=request.user.company,
                created_by=request.user,
            )
            ProjectMember.objects.create(
                project=project,
                user=request.user,
                role='ADMIN',
            )
            ActivityLog.objects.create(
                company=request.user.company,
                actor=request.user,
                action_type='PROJECT_CREATED',
                target_description=f'Projet "{project.title}" créé',
                metadata={'project_id': str(project.id)},
            )
            return Response(
                ProjectSerializer(project).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH', 'DELETE'])
def project_detail(request, pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
    except Project.DoesNotExist:
        return Response({'error': 'Projet introuvable.'}, status=404)

    if request.method == 'GET':
        return Response(ProjectSerializer(project).data)

    if request.method == 'PATCH':
        if not require_project_role(project, request.user, ['ADMIN', 'LEAD']):
            return Response({'error': 'Action non autorisée.'}, status=403)
        serializer = ProjectSerializer(project, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

    if request.method == 'DELETE':
        if not require_project_role(project, request.user, ['ADMIN']):
            return Response({'error': 'Action non autorisée.'}, status=403)
        project.delete()
        return Response(status=204)


@api_view(['POST'])
def update_project_status(request, pk, action):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
    except Project.DoesNotExist:
        return Response({'error': 'Projet introuvable.'}, status=404)

    if not require_project_role(project, request.user, ['ADMIN', 'LEAD']):
        return Response({'error': 'Action non autorisée.'}, status=403)

    valid_actions = {
        'activate': 'ACTIVE',
        'validate': 'COMPLETED',
        'archive': 'ARCHIVED',
        'draft': 'DRAFT',
        'hold': 'ON_HOLD',
        'plan': 'PLANNING',
    }
    if action not in valid_actions:
        return Response({'error': 'Action invalide.'}, status=400)

    project.status = valid_actions[action]
    project.save()

    ActivityLog.objects.create(
        company=request.user.company,
        actor=request.user,
        action_type='PROJECT_UPDATED',
        target_description=f'Projet "{project.title}" : {project.get_status_display()}',
        metadata={'project_id': str(project.id), 'status': project.status},
    )
    return Response({'status': project.status})


@api_view(['GET'])
def dashboard_stats(request):
    company = request.user.company
    projects = Project.objects.filter(company=company)
    tasks = Task.objects.filter(project__company=company)
    members = User.objects.filter(company=company)

    return Response({
        'total_projects': projects.count(),
        'active_tasks': tasks.filter(status__in=['TODO', 'IN_PROGRESS', 'REVIEW']).count(),
        'total_members': members.count(),
    })


@api_view(['GET'])
def project_stats(request, pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
    except Project.DoesNotExist:
        return Response({'error': 'Projet introuvable.'}, status=404)

    tasks = Task.objects.filter(project=project)
    total = tasks.count()
    done = tasks.filter(status='DONE').count()
    overdue = tasks.filter(
        due_date__lt=timezone.now().date(),
        status__in=['TODO', 'IN_PROGRESS', 'REVIEW']
    ).count()

    by_status = {}
    for status_choice, _ in Task.STATUS_CHOICES:
        count = tasks.filter(status=status_choice).count()
        if count > 0:
            by_status[status_choice] = count

    per_member = []
    for pm in ProjectMember.objects.filter(project=project).select_related('user'):
        count = tasks.filter(assigned_to=pm.user).count()
        per_member.append({
            'user': f'{pm.user.first_name} {pm.user.last_name}'.strip(),
            'count': count,
        })

    data = {
        'total_tasks': total,
        'completion_rate': (done / total * 100) if total > 0 else 0,
        'tasks_by_status': by_status,
        'tasks_per_member': per_member,
        'overdue_tasks': overdue,
    }
    return Response(data)


# ─── Project Members ───────────────────────────────────────────────

@api_view(['GET', 'POST'])
def project_members(request, pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
    except Project.DoesNotExist:
        return Response({'error': 'Projet introuvable.'}, status=404)

    if request.method == 'GET':
        members = ProjectMember.objects.filter(project=project).select_related('user')
        return Response(ProjectMemberSerializer(members, many=True).data)

    if request.method == 'POST':
        if not require_project_role(project, request.user, ['ADMIN', 'LEAD']):
            return Response({'error': 'Action non autorisée.'}, status=403)
        user_id = request.data.get('user')
        role = request.data.get('role', 'MEMBER')
        try:
            user = User.objects.get(id=user_id, company=request.user.company)
        except User.DoesNotExist:
            return Response({'error': 'Utilisateur introuvable.'}, status=404)

        member, created = ProjectMember.objects.get_or_create(
            project=project, user=user, defaults={'role': role}
        )
        if not created:
            member.role = role
            member.save()

        return Response(
            ProjectMemberSerializer(member).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


@api_view(['DELETE', 'PATCH'])
def project_member_detail(request, pk, member_pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
        member = ProjectMember.objects.get(id=member_pk, project=project)
    except (Project.DoesNotExist, ProjectMember.DoesNotExist):
        return Response({'error': 'Membre introuvable.'}, status=404)

    if request.method == 'DELETE':
        if not require_project_role(project, request.user, ['ADMIN', 'LEAD']):
            return Response({'error': 'Action non autorisée.'}, status=403)
        member.delete()
        return Response(status=204)

    if request.method == 'PATCH':
        if not require_project_role(project, request.user, ['ADMIN']):
            return Response({'error': 'Action non autorisée.'}, status=403)
        role = request.data.get('role')
        if role:
            member.role = role
            member.save()
        return Response(ProjectMemberSerializer(member).data)


# ─── Tasks ─────────────────────────────────────────────────────────

@api_view(['GET', 'POST'])
def task_list(request, pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
    except Project.DoesNotExist:
        return Response({'error': 'Projet introuvable.'}, status=404)

    if request.method == 'GET':
        tasks = Task.objects.filter(project=project).select_related('assigned_to')
        status_filter = request.query_params.get('status')
        assigned = request.query_params.get('assigned_to')
        if status_filter:
            tasks = tasks.filter(status=status_filter)
        if assigned:
            tasks = tasks.filter(assigned_to=assigned)
        tasks = apply_search_and_ordering(tasks, request, ['title', 'description'])

        paginator = PageNumberPagination()
        paginator.page_size = 20
        result_page = paginator.paginate_queryset(tasks, request)
        serializer = TaskSerializer(result_page, many=True)
        return paginator.get_paginated_response(serializer.data)

    if request.method == 'POST':
        serializer = TaskSerializer(data=request.data)
        if serializer.is_valid():
            task = serializer.save(project=project, created_by=request.user)
            ActivityLog.objects.create(
                company=request.user.company,
                actor=request.user,
                action_type='TASK_CREATED',
                target_description=f'Tâche "{task.title}" créée',
                metadata={
                    'project_id': str(project.id),
                    'task_id': str(task.id),
                },
            )
            return Response(
                TaskSerializer(task).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=400)


@api_view(['GET'])
def task_detail(request, pk, task_pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
        task = Task.objects.get(id=task_pk, project=project)
    except (Project.DoesNotExist, Task.DoesNotExist):
        return Response({'error': 'Tâche introuvable.'}, status=404)

    return Response(TaskSerializer(task).data)


@api_view(['PATCH'])
def update_task_status(request, pk, task_pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
        task = Task.objects.get(id=task_pk, project=project)
    except (Project.DoesNotExist, Task.DoesNotExist):
        return Response({'error': 'Tâche introuvable.'}, status=404)

    serializer = TaskStatusSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)

    task.status = serializer.validated_data['status']
    task.save()

    ActivityLog.objects.create(
        company=request.user.company,
        actor=request.user,
        action_type='TASK_UPDATED',
        target_description=f'Tâche "{task.title}" : {task.get_status_display()}',
        metadata={
            'project_id': str(project.id),
            'task_id': str(task.id),
            'status': task.status,
        },
    )
    return Response({'status': task.status})


@api_view(['PATCH'])
def reorder_tasks(request, pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
    except Project.DoesNotExist:
        return Response({'error': 'Projet introuvable.'}, status=404)

    serializer = TaskReorderSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)

    try:
        task = Task.objects.get(id=serializer.validated_data['task_id'], project=project)
    except Task.DoesNotExist:
        return Response({'error': 'Tâche introuvable.'}, status=404)

    task.status = serializer.validated_data['new_status']
    task.order = serializer.validated_data['new_order']
    task.save()
    return Response({'status': task.status, 'order': task.order})


# ─── User Tasks ────────────────────────────────────────────────────

@api_view(['GET'])
def my_tasks(request):
    tasks = Task.objects.filter(assigned_to=request.user).select_related('project')
    paginator = PageNumberPagination()
    paginator.page_size = 20
    result_page = paginator.paginate_queryset(tasks, request)
    serializer = TaskSerializer(result_page, many=True)
    return paginator.get_paginated_response(serializer.data)


@api_view(['GET'])
def task_activity(request):
    from activity.models import ActivityLog
    activities = ActivityLog.objects.filter(company=request.user.company)
    limit = int(request.query_params.get('limit', 50))
    activities = activities.select_related('actor').order_by('-timestamp')[:limit]

    from activity.serializers import ActivityLogSerializer
    return Response(ActivityLogSerializer(activities, many=True).data)


# ─── Comments ──────────────────────────────────────────────────────

@api_view(['POST'])
def add_comment(request, pk, task_pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
        task = Task.objects.get(id=task_pk, project=project)
    except (Project.DoesNotExist, Task.DoesNotExist):
        return Response({'error': 'Tâche introuvable.'}, status=404)

    serializer = CommentSerializer(data=request.data)
    if serializer.is_valid():
        comment = serializer.save(task=task, author=request.user)
        return Response(
            CommentSerializer(comment).data,
            status=status.HTTP_201_CREATED,
        )
    return Response(serializer.errors, status=400)


# ─── Subtasks ──────────────────────────────────────────────────────

@api_view(['POST', 'PATCH'])
def subtask_detail(request, pk, task_pk, subtask_pk=None):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
        task = Task.objects.get(id=task_pk, project=project)
    except (Project.DoesNotExist, Task.DoesNotExist):
        return Response({'error': 'Tâche introuvable.'}, status=404)

    if request.method == 'POST':
        serializer = ChecklistItemSerializer(data=request.data)
        if serializer.is_valid():
            item = serializer.save(task=task)
            return Response(
                ChecklistItemSerializer(item).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=400)

    if request.method == 'PATCH' and subtask_pk:
        try:
            item = ChecklistItem.objects.get(id=subtask_pk, task=task)
        except ChecklistItem.DoesNotExist:
            return Response({'error': 'Sous-tâche introuvable.'}, status=404)

        serializer = ChecklistItemSerializer(item, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


# ─── Attachments ──────────────────────────────────────────────────

@api_view(['POST'])
def upload_attachment(request, pk, task_pk):
    try:
        project = Project.objects.get(id=pk, company=request.user.company)
        task = Task.objects.get(id=task_pk, project=project)
    except (Project.DoesNotExist, Task.DoesNotExist):
        return Response({'error': 'Tâche introuvable.'}, status=404)

    if 'file' not in request.FILES:
        return Response({'error': 'Fichier requis.'}, status=400)

    file = request.FILES['file']
    attachment = Attachment.objects.create(
        task=task,
        file=file,
        original_filename=file.name,
        file_size=file.size,
        uploaded_by=request.user,
    )
    return Response(
        AttachmentSerializer(attachment).data,
        status=status.HTTP_201_CREATED,
    )
