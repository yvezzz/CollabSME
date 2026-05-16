from django.contrib import admin
from .models import Invitation


@admin.register(Invitation)
class InvitationAdmin(admin.ModelAdmin):
    list_display = ('email', 'company', 'role', 'status', 'created_at')
    list_filter = ('status', 'role')
    search_fields = ('email',)
