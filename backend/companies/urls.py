from django.urls import path
from . import views

urlpatterns = [
    path('detail/', views.company_detail, name='company-detail'),
    path('members/', views.company_members, name='company-members'),
    path('members/<int:user_id>/remove/', views.remove_member, name='remove-member'),
    path('members/<int:user_id>/role/', views.change_member_role, name='change-member-role'),
]
