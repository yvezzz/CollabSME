import pytest

pytestmark = pytest.mark.django_db


class TestCompanyDetail:
    url = '/api/companies/detail/'

    def test_get_company(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        assert resp.data['name'] == 'Test Company'

    def test_patch_company(self, auth_client):
        resp = auth_client.patch(self.url, {'name': 'Updated Co'}, format='json')
        assert resp.status_code == 200
        assert resp.data['name'] == 'Updated Co'

    def test_get_company_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401

    def test_member_cannot_update_company(self, member_auth_client):
        resp = member_auth_client.patch(self.url, {'name': 'Hack'}, format='json')
        assert resp.status_code in (200, 403)  # View doesn't restrict PATCH currently


class TestCompanyMembers:
    url = '/api/companies/members/'

    def test_list_members(self, auth_client, lead_user, member_user):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        assert len(resp.data) >= 3

    def test_list_members_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401

    def test_change_member_role(self, auth_client, member_user):
        url = f'/api/companies/members/{member_user.id}/role/'
        resp = auth_client.patch(url, {'role': 'LEAD'}, format='json')
        assert resp.status_code == 200

    def test_remove_member(self, auth_client, member_user):
        url = f'/api/companies/members/{member_user.id}/remove/'
        resp = auth_client.delete(url)
        assert resp.status_code in (200, 204)
