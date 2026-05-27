from rest_framework import serializers
from .models import Project, ProjectMember, ProjectTemplate, Task, ChecklistItem, Comment, Attachment


class ChecklistItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChecklistItem
        fields = ['id', 'title', 'is_completed', 'order']


class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    replies = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            'id', 'parent', 'content', 'author_name', 'mentions',
            'reactions', 'created_at', 'replies',
        ]
        read_only_fields = ['id', 'author_name', 'created_at', 'replies']

    def get_author_name(self, obj):
        if obj.author:
            return f'{obj.author.first_name} {obj.author.last_name}'.strip()
        return 'Inconnu'

    def get_replies(self, obj):
        replies = obj.replies.all()
        return CommentSerializer(replies, many=True).data


class AttachmentSerializer(serializers.ModelSerializer):
    uploaded_by_details = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Attachment
        fields = [
            'id', 'original_filename', 'file_url', 'file_size',
            'uploaded_by_details', 'uploaded_at',
        ]
        read_only_fields = ['id', 'file_url', 'uploaded_at', 'uploaded_by_details']

    def get_uploaded_by_details(self, obj):
        if obj.uploaded_by:
            return {
                'full_name': f'{obj.uploaded_by.first_name} {obj.uploaded_by.last_name}'.strip()
            }
        return {'full_name': 'Inconnu'}

    def get_file_url(self, obj):
        if obj.file:
            return obj.file.url
        return ''


class TaskSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.SerializerMethodField()
    sub_tasks_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    attachments_count = serializers.SerializerMethodField()
    checklist_items = ChecklistItemSerializer(many=True, read_only=True)
    comments = CommentSerializer(many=True, read_only=True)
    project_title = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'id', 'public_id', 'parent_task', 'project', 'project_title', 'title', 'description',
            'status', 'priority', 'assigned_to', 'assigned_to_name',
            'estimated_hours', 'actual_hours', 'tags', 'custom_fields',
            'order', 'created_at', 'updated_at', 'due_date', 'start_date',
            'checklist_items', 'comments', 'sub_tasks_count',
            'comments_count', 'attachments_count',
        ]
        read_only_fields = ['id', 'public_id', 'created_at', 'updated_at',
                           'checklist_items', 'comments', 'order',
                           'sub_tasks_count', 'comments_count', 'attachments_count',
                           'project']

    def get_assigned_to_name(self, obj):
        if obj.assigned_to:
            return f'{obj.assigned_to.first_name} {obj.assigned_to.last_name}'.strip()
        return None

    def get_project_title(self, obj):
        return obj.project.title if obj.project else None

    def get_sub_tasks_count(self, obj):
        return obj.sub_tasks.count()

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_attachments_count(self, obj):
        return obj.attachments.count()


class TaskStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=[
        'TODO', 'IN_PROGRESS', 'REVIEW', 'DONE'
    ])


class TaskReorderSerializer(serializers.Serializer):
    task_id = serializers.CharField()
    new_status = serializers.ChoiceField(choices=[
        'TODO', 'IN_PROGRESS', 'REVIEW', 'DONE'
    ])
    new_order = serializers.IntegerField()


class ProjectMemberSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_first_name = serializers.CharField(source='user.first_name', read_only=True)
    user_last_name = serializers.CharField(source='user.last_name', read_only=True)
    user_avatar = serializers.URLField(source='user.avatar_url', read_only=True)

    class Meta:
        model = ProjectMember
        fields = [
            'id', 'user', 'user_email', 'user_first_name',
            'user_last_name', 'user_avatar', 'role', 'joined_at',
        ]
        read_only_fields = ['id', 'joined_at']

    def create(self, validated_data):
        project = self.context.get('project')
        if project:
            validated_data['project'] = project
        return super().create(validated_data)


class ProjectSerializer(serializers.ModelSerializer):
    tasks = TaskSerializer(many=True, read_only=True)
    task_completion_percentage = serializers.IntegerField(read_only=True)
    member_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Project
        fields = [
            'id', 'key', 'title', 'description', 'status', 'priority',
            'budget', 'actual_cost', 'tags', 'custom_fields',
            'created_by', 'created_at', 'updated_at',
            'start_date', 'end_date', 'company',
            'tasks', 'task_completion_percentage', 'member_count',
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at',
                           'tasks', 'task_completion_percentage', 'member_count',
                           'actual_cost', 'company']


class ProjectTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectTemplate
        fields = ['id', 'name', 'description', 'icon', 'is_public', 'tasks', 'created_at']


class ProjectStatsSerializer(serializers.Serializer):
    total_tasks = serializers.IntegerField()
    completion_rate = serializers.FloatField()
    tasks_by_status = serializers.DictField(child=serializers.IntegerField())
    tasks_per_member = serializers.ListField()
    overdue_tasks = serializers.IntegerField()
