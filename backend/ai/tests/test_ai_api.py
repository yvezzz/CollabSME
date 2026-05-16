import pytest

pytestmark = pytest.mark.django_db


class TestAI:
    def test_generate_task(self, auth_client):
        resp = auth_client.post('/api/ai/generate-task/', {
            'title': 'Build login page',
            'project_id': 1,
        }, format='json')
        assert resp.status_code in (200, 503)

    def test_summarize_project(self, auth_client):
        # Create a project first
        proj = auth_client.post('/api/projects/', {
            'title': 'AI Summary Test', 'key': 'AI',
        }, format='json')
        pk = proj.data['id']
        resp = auth_client.post('/api/ai/summarize-project/', {
            'project_id': pk,
        }, format='json')
        assert resp.status_code in (200, 503)

    def test_chat(self, auth_client):
        resp = auth_client.post('/api/ai/chat/', {'message': 'Hello'}, format='json')
        assert resp.status_code in (200, 503)

    def test_chat_history(self, auth_client):
        resp = auth_client.get('/api/ai/chat/history/')
        assert resp.status_code == 200

    def test_clear_history(self, auth_client):
        resp = auth_client.delete('/api/ai/clear/')
        assert resp.status_code == 204
