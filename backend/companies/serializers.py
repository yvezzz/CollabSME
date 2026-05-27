from rest_framework import serializers
from .models import Company


class CompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = Company
        fields = [
            'id', 'name', 'sector', 'size', 'website', 'billing_email',
            'address', 'city', 'postal_code', 'country', 'logo_url',
            'subscription_status', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'subscription_status', 'created_at', 'updated_at']
