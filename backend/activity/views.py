from rest_framework.decorators import api_view
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import ActivityLog
from .serializers import ActivityLogSerializer


@api_view(['GET'])
def activity_list(request):
    activities = ActivityLog.objects.filter(company=request.user.company)
    activities = activities.select_related('actor')

    action_type = request.query_params.get('action_type')
    if action_type:
        activities = activities.filter(action_type=action_type)

    project_id = request.query_params.get('project_id')
    if project_id:
        activities = activities.filter(metadata__project_id=project_id)

    paginator = PageNumberPagination()
    paginator.page_size = 20
    result_page = paginator.paginate_queryset(activities, request)
    serializer = ActivityLogSerializer(result_page, many=True)
    return paginator.get_paginated_response(serializer.data)
