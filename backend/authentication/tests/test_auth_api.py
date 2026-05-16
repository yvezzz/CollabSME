import pytest

pytestmark = pytest.mark.django_db


class TestRegister:
    url = '/api/auth/register/'

    def test_register_success(self, api_client):
        data = {
            'first_name': 'John',
            'last_name': 'Doe',
            'email': 'john@example.com',
            'password': 'Str0ng!Pass',
            'company_name': 'New Corp',
        }
        resp = api_client.post(self.url, data, format='json')
        assert resp.status_code == 201
        assert 'tokens' in resp.data
        assert resp.data['user']['email'] == 'john@example.com'

    def test_register_missing_fields(self, api_client):
        resp = api_client.post(self.url, {'email': 'bad'}, format='json')
        assert resp.status_code == 400

    def test_register_duplicate_email(self, api_client, admin_user):
        data = {
            'first_name': 'Other',
            'last_name': 'User',
            'email': 'admin@test.com',
            'password': 'Str0ng!Pass',
            'company_name': 'Other Corp',
        }
        resp = api_client.post(self.url, data, format='json')
        assert resp.status_code == 400


class TestLogin:
    url = '/api/auth/login/'

    def test_login_success(self, api_client, admin_user):
        resp = api_client.post(self.url, {
            'email': 'admin@test.com',
            'password': 'Test@123456',
        }, format='json')
        assert resp.status_code == 200
        assert 'access' in resp.data
        assert 'refresh' in resp.data

    def test_login_wrong_password(self, api_client, admin_user):
        resp = api_client.post(self.url, {
            'email': 'admin@test.com',
            'password': 'wrong',
        }, format='json')
        assert resp.status_code == 401

    def test_login_nonexistent(self, api_client):
        resp = api_client.post(self.url, {
            'email': 'nobody@test.com',
            'password': 'x',
        }, format='json')
        assert resp.status_code == 401


class TestMe:
    url = '/api/auth/me/'

    def test_get_profile(self, auth_client, admin_user):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        assert resp.data['email'] == 'admin@test.com'

    def test_get_profile_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401

    def test_patch_profile(self, auth_client):
        resp = auth_client.patch(self.url, {'first_name': 'Updated'}, format='json')
        assert resp.status_code == 200
        assert resp.data['first_name'] == 'Updated'

    def test_delete_profile(self, auth_client):
        resp = auth_client.delete(self.url)
        assert resp.status_code == 204


class TestCompanyUsers:
    url = '/api/auth/users/'

    def test_list_users(self, auth_client, lead_user, member_user):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        assert len(resp.data) >= 3

    def test_list_users_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401


class TestTokenRefresh:
    url = '/api/auth/token/refresh/'

    def test_refresh_success(self, api_client, admin_user):
        login_resp = api_client.post('/api/auth/login/', {
            'email': 'admin@test.com', 'password': 'Test@123456',
        }, format='json')
        refresh = login_resp.data['refresh']
        resp = api_client.post(self.url, {'refresh': refresh}, format='json')
        assert resp.status_code == 200
        assert 'access' in resp.data


class TestLogout:
    url = '/api/auth/logout/'

    def test_logout_success(self, auth_client, admin_user):
        login_resp = auth_client.post('/api/auth/login/', {
            'email': 'admin@test.com', 'password': 'Test@123456',
        }, format='json')
        refresh = login_resp.data['refresh']
        resp = auth_client.post(self.url, {'refresh': refresh}, format='json')
        assert resp.status_code == 200


class TestPasswordReset:
    def test_request_reset(self, api_client, admin_user):
        resp = api_client.post('/api/auth/password-reset/', {
            'email': 'admin@test.com',
        }, format='json')
        assert resp.status_code == 200

    def test_request_reset_nonexistent(self, api_client):
        resp = api_client.post('/api/auth/password-reset/', {
            'email': 'noone@test.com',
        }, format='json')
        assert resp.status_code == 200  # Always 200 to avoid enumeration
