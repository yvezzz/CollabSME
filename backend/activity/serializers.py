from rest_framework import serializers
from .models import ActivityLog


class ActivityLogSerializer(serializers.ModelSerializer):
    actor_name = serializers.SerializerMethodField()
    actor_avatar = serializers.SerializerMethodField()

    class Meta:
        model = ActivityLog
        fields = [
            'id', 'actor_name', 'actor_avatar', 'action_type',
            'target_description', 'timestamp', 'metadata',
        ]

    def get_actor_name(self, obj):
        if obj.actor:
            return f'{obj.actor.first_name} {obj.actor.last_name}'.strip()
        return 'Système'

    def get_actor_avatar(self, obj):
        if obj.actor:
            return obj.actor.avatar_url
        return None
