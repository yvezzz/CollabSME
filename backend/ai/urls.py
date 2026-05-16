from django.urls import path
from . import views

urlpatterns = [
    path('chat/', views.chat, name='ai-chat'),
    path('chat/history/', views.chat_history, name='ai-chat-history'),
    path('clear/', views.clear_chat_history, name='ai-clear-history'),
    path('generate-task/', views.generate_task, name='ai-generate-task'),
    path('summarize-project/', views.summarize_project, name='ai-summarize-project'),
]
