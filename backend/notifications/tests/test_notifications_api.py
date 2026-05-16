import pytest

pytestmark = pytest.mark.django_db


class TestNotifications:
    url = '/api/notifications/'

    def test_list_notifications(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200

    def test_list_notifications_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401

    def test_mark_as_read(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        data = resp.data
        results = data.get('results', data if isinstance(data, list) else [])
        if len(results) > 0:
            nid = results[0]['id']
            patch_resp = auth_client.post(f'/api/notifications/{nid}/mark_as_read/')
            assert patch_resp.status_code == 200

    def test_unread_count(self, auth_client):
        resp = auth_client.get('/api/notifications/unread_count/')
        assert resp.status_code == 200
        assert 'unread_count' in resp.data
