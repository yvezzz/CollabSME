from django.urls import path
from . import views

urlpatterns = [
    path('', views.invitation_list, name='invitation-list'),
    path('<int:pk>/', views.cancel_invitation, name='cancel-invitation'),
    path('validate/<uuid:token>/', views.validate_invitation, name='validate-invitation'),
    path('accept/<uuid:token>/', views.accept_invitation, name='accept-invitation'),
    path('decline/<uuid:token>/', views.decline_invitation, name='decline-invitation'),
]
