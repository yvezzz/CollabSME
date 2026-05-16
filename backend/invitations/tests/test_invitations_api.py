import pytest

pytestmark = pytest.mark.django_db


class TestInvitations:
    url = '/api/invitations/'

    def test_create_invitation(self, auth_client):
        resp = auth_client.post(self.url, {
            'email': 'invitee@test.com', 'role': 'MEMBER',
        }, format='json')
        assert resp.status_code == 201

    def test_list_invitations(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200

    def test_create_invitation_member_forbidden(self, member_auth_client):
        resp = member_auth_client.post(self.url, {
            'email': 'other@test.com', 'role': 'MEMBER',
        }, format='json')
        assert resp.status_code == 403

    def test_cancel_invitation(self, auth_client):
        inv = auth_client.post(self.url, {
            'email': 'cancel@test.com', 'role': 'MEMBER',
        }, format='json')
        inv_id = inv.data['id']
        resp = auth_client.delete(f'{self.url}{inv_id}/')
        assert resp.status_code == 204
