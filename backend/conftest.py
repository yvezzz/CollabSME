import pytest
from rest_framework.test import APIClient
from authentication.models import User
from companies.models import Company


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def company():
    return Company.objects.create(name="Test Company")


@pytest.fixture
def admin_user(company):
    return User.objects.create_user(
        email="admin@test.com",
        password="Test@123456",
        first_name="Admin",
        last_name="User",
        company=company,
        role="ADMIN",
        is_company_admin=True,
    )


@pytest.fixture
def lead_user(company):
    return User.objects.create_user(
        email="lead@test.com",
        password="Test@123456",
        first_name="Lead",
        last_name="User",
        company=company,
        role="LEAD",
    )


@pytest.fixture
def member_user(company):
    return User.objects.create_user(
        email="member@test.com",
        password="Test@123456",
        first_name="Member",
        last_name="User",
        company=company,
        role="MEMBER",
    )


@pytest.fixture
def auth_client(api_client, admin_user):
    api_client.force_authenticate(user=admin_user)
    return api_client


@pytest.fixture
def lead_auth_client(api_client, lead_user):
    api_client.force_authenticate(user=lead_user)
    return api_client


@pytest.fixture
def member_auth_client(api_client, member_user):
    api_client.force_authenticate(user=member_user)
    return api_client


@pytest.fixture(autouse=True)
def disable_throttle(settings):
    settings.REST_FRAMEWORK = {
        **settings.REST_FRAMEWORK,
        'DEFAULT_THROTTLE_RATES': {'anon': None, 'user': None, 'login': None},
    }
