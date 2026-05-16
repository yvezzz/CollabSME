from django.urls import path
from . import views

urlpatterns = [
    path('my-tasks/', views.my_tasks, name='my-tasks'),
    path('activity/', views.task_activity, name='task-activity'),
]
