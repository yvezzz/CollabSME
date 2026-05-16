from rest_framework import serializers
from .models import AIChat


class AIChatSerializer(serializers.ModelSerializer):
    class Meta:
        model = AIChat
        fields = ['id', 'role', 'content', 'model_used', 'created_at']
        read_only_fields = ['id', 'created_at']
