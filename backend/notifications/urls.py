from django.urls import path
from . import views

urlpatterns = [
    path('', views.notification_list, name='notification-list'),
    path('unread_count/', views.unread_count, name='unread-count'),
    path('<int:pk>/mark_as_read/', views.mark_as_read, name='mark-as-read'),
    path('mark_all_as_read/', views.mark_all_as_read, name='mark-all-as-read'),
]
