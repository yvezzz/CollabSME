import pytest

pytestmark = pytest.mark.django_db


class TestActivityLog:
    url = '/api/activity/'

    def test_list_activity(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        assert 'results' in resp.data

    def test_list_activity_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401

    def test_filter_by_action_type(self, auth_client):
        resp = auth_client.get(self.url, {'action_type': 'PROJECT_CREATED'})
        assert resp.status_code == 200
        assert 'results' in resp.data
