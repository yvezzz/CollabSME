import logging

from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import Notification
from .serializers import NotificationSerializer

logger = logging.getLogger(__name__)


@api_view(['GET'])
def notification_list(request):
    notifications = Notification.objects.filter(user=request.user)
    paginator = PageNumberPagination()
    paginator.page_size = 20
    result_page = paginator.paginate_queryset(notifications, request)
    serializer = NotificationSerializer(result_page, many=True)
    return paginator.get_paginated_response(serializer.data)


@api_view(['GET'])
def unread_count(request):
    count = Notification.objects.filter(user=request.user, is_read=False).count()
    return Response({'unread_count': count})


@api_view(['POST'])
def mark_as_read(request, pk):
    try:
        notification = Notification.objects.get(id=pk, user=request.user)
    except Notification.DoesNotExist:
        return Response({'error': 'Notification introuvable.'}, status=404)

    notification.is_read = True
    notification.save()
    return Response(NotificationSerializer(notification).data)


@api_view(['POST'])
def mark_all_as_read(request):
    updated = Notification.objects.filter(
        user=request.user, is_read=False
    ).update(is_read=True)
    return Response({'updated': updated})
