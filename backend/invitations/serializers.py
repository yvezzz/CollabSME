from rest_framework import serializers
from .models import Invitation


class InvitationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invitation
        fields = [
            'id', 'email', 'role', 'token', 'status',
            'invited_by', 'created_at',
        ]
        read_only_fields = ['id', 'token', 'status', 'invited_by', 'created_at']
