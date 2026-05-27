from django.urls import path
from . import views

urlpatterns = [
    # Dashboard
    path('dashboard/stats/', views.dashboard_stats, name='dashboard-stats'),
    path('reports/', views.project_reports, name='project-reports'),
    path('search/', views.global_search, name='project-search'),
    path('calendar/', views.calendar_tasks, name='calendar-tasks'),
    # Project CRUD
    path('', views.project_list, name='project-list'),
    path('<int:pk>/', views.project_detail, name='project-detail'),
    # Specific sub-routes MUST come before the generic <str:action> catch-all
    path('<int:pk>/stats/', views.project_stats, name='project-stats'),
    path('<int:pk>/members/', views.project_members, name='project-members'),
    path('<int:pk>/members/<int:member_pk>/', views.project_member_detail, name='project-member-detail'),
    path('<int:pk>/workload/', views.project_workload, name='project-workload'),
    path('<int:pk>/tasks/', views.task_list, name='task-list'),
    path('<int:pk>/tasks/<int:task_pk>/', views.task_detail, name='task-detail'),
    path('<int:pk>/tasks/<int:task_pk>/status/', views.update_task_status, name='task-status'),
    path('<int:pk>/tasks/reorder/', views.reorder_tasks, name='task-reorder'),
    path('<int:pk>/tasks/<int:task_pk>/comments/', views.add_comment, name='add-comment'),
    path('<int:pk>/tasks/<int:task_pk>/subtasks/', views.subtask_detail, name='create-subtask'),
    path('<int:pk>/tasks/<int:task_pk>/subtasks/<int:subtask_pk>/', views.subtask_detail, name='subtask-detail'),
    path('<int:pk>/tasks/<int:task_pk>/attachments/', views.upload_attachment, name='upload-attachment'),
    # Templates
    path('templates/', views.template_list, name='template-list'),
    path('templates/create-from-template/', views.create_from_template, name='create-from-template'),
    # Status actions catch-all (last, so specific routes take priority)
    path('<int:pk>/<str:action>/', views.update_project_status, name='project-status'),
]


