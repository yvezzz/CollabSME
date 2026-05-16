from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone_number', 'company', 'role', 'is_company_admin',
            'avatar_url', 'bio', 'preferences',
        ]
        read_only_fields = ['id', 'company', 'role', 'is_company_admin']

    def get_full_name(self, obj):
        return f'{obj.first_name} {obj.last_name}'.strip()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    company_name = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            'first_name', 'last_name', 'email', 'password',
            'phone_number', 'company_name',
        ]

    def create(self, validated_data):
        company_name = validated_data.pop('company_name')
        password = validated_data.pop('password')

        from companies.models import Company
        company = Company.objects.create(name=company_name)

        user = User.objects.create_user(
            password=password,
            company=company,
            role='ADMIN',
            is_company_admin=True,
            **validated_data
        )
        return user


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    token = serializers.CharField()
    new_password = serializers.CharField(validators=[validate_password])


class PasswordResetConfirmUidSerializer(serializers.Serializer):
    uid = serializers.CharField()
    token = serializers.CharField()
    new_password = serializers.CharField(validators=[validate_password])
