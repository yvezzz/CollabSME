from django.contrib import admin
from .models import AIChat


@admin.register(AIChat)
class AIChatAdmin(admin.ModelAdmin):
    list_display = ('user', 'role', 'created_at')
    list_filter = ('role',)
