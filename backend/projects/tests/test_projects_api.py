import pytest

pytestmark = pytest.mark.django_db


class TestProjectList:
    url = '/api/projects/'

    def test_list_projects(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200

    def test_create_project(self, auth_client):
        data = {'title': 'New Project', 'key': 'NP', 'description': 'Test'}
        resp = auth_client.post(self.url, data, format='json')
        assert resp.status_code == 201
        assert resp.data['title'] == 'New Project'

    def test_create_project_member(self, member_auth_client):
        data = {'title': 'Member Project', 'key': 'MP'}
        resp = member_auth_client.post(self.url, data, format='json')
        assert resp.status_code == 201

    def test_create_project_unauthorized(self, api_client):
        resp = api_client.post(self.url, {'title': 'X'}, format='json')
        assert resp.status_code == 401


class TestProjectDetail:
    def test_get_project(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Detail Test', 'key': 'DT'}, format='json')
        pk = proj.data['id']
        resp = auth_client.get(f'/api/projects/{pk}/')
        assert resp.status_code == 200
        assert resp.data['title'] == 'Detail Test'

    def test_update_project(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Update Test', 'key': 'UT'}, format='json')
        pk = proj.data['id']
        resp = auth_client.patch(f'/api/projects/{pk}/', {'title': 'Updated'}, format='json')
        assert resp.status_code == 200
        assert resp.data['title'] == 'Updated'

    def test_delete_project(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Delete Test', 'key': 'DEL'}, format='json')
        pk = proj.data['id']
        resp = auth_client.delete(f'/api/projects/{pk}/')
        assert resp.status_code == 204

    def test_get_project_not_found(self, auth_client):
        resp = auth_client.get('/api/projects/99999/')
        assert resp.status_code == 404


class TestProjectMembers:
    def test_add_member(self, auth_client, member_user):
        proj = auth_client.post('/api/projects/', {'title': 'Members Test', 'key': 'MT'}, format='json')
        pk = proj.data['id']
        resp = auth_client.post(f'/api/projects/{pk}/members/', {
            'user': member_user.id, 'role': 'MEMBER',
        }, format='json')
        assert resp.status_code == 201

    def test_list_members(self, auth_client, member_user):
        proj = auth_client.post('/api/projects/', {'title': 'Members List', 'key': 'ML'}, format='json')
        pk = proj.data['id']
        auth_client.post(f'/api/projects/{pk}/members/', {
            'user': member_user.id, 'role': 'MEMBER',
        }, format='json')
        resp = auth_client.get(f'/api/projects/{pk}/members/')
        assert resp.status_code == 200
        assert len(resp.data) >= 1


class TestProjectDashboard:
    url = '/api/projects/dashboard/stats/'

    def test_dashboard_stats(self, auth_client):
        resp = auth_client.get(self.url)
        assert resp.status_code == 200
        assert 'total_projects' in resp.data

    def test_dashboard_unauthorized(self, api_client):
        resp = api_client.get(self.url)
        assert resp.status_code == 401


class TestProjectStats:
    def test_project_stats(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Stats Test', 'key': 'ST'}, format='json')
        pk = proj.data['id']
        resp = auth_client.get(f'/api/projects/{pk}/stats/')
        assert resp.status_code == 200


class TestProjectStatus:
    def test_update_status(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Status Test', 'key': 'STAT'}, format='json')
        pk = proj.data['id']
        resp = auth_client.patch(f'/api/projects/{pk}/', {'status': 'ACTIVE'}, format='json')
        assert resp.status_code == 200
        assert resp.data['status'] == 'ACTIVE'


class TestTasks:
    def test_create_task(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Task Test', 'key': 'TT'}, format='json')
        pk = proj.data['id']
        resp = auth_client.post(f'/api/projects/{pk}/tasks/', {
            'title': 'Test Task', 'status': 'TODO',
        }, format='json')
        assert resp.status_code == 201

    def test_list_tasks(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Task List', 'key': 'TL'}, format='json')
        pk = proj.data['id']
        resp = auth_client.get(f'/api/projects/{pk}/tasks/')
        assert resp.status_code == 200

    def test_update_task_status(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Task Status', 'key': 'TS'}, format='json')
        pk = proj.data['id']
        task = auth_client.post(f'/api/projects/{pk}/tasks/', {
            'title': 'Status Task', 'status': 'TODO',
        }, format='json')
        task_id = task.data['id']
        resp = auth_client.patch(f'/api/projects/{pk}/tasks/{task_id}/status/', {
            'status': 'IN_PROGRESS',
        }, format='json')
        assert resp.status_code == 200
        assert resp.data['status'] == 'IN_PROGRESS'

    def test_reorder_task(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Reorder', 'key': 'RO'}, format='json')
        pk = proj.data['id']
        t1 = auth_client.post(f'/api/projects/{pk}/tasks/', {'title': 'A', 'status': 'TODO'}, format='json')
        t2 = auth_client.post(f'/api/projects/{pk}/tasks/', {'title': 'B', 'status': 'TODO'}, format='json')
        resp = auth_client.patch(f'/api/projects/{pk}/tasks/reorder/', {
            'task_id': t1.data['id'], 'new_status': 'TODO', 'new_order': 1,
        }, format='json')
        assert resp.status_code == 200

    def test_add_comment(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Comments', 'key': 'CM'}, format='json')
        pk = proj.data['id']
        task = auth_client.post(f'/api/projects/{pk}/tasks/', {'title': 'C', 'status': 'TODO'}, format='json')
        resp = auth_client.post(f'/api/projects/{pk}/tasks/{task.data["id"]}/comments/', {
            'content': 'Hello',
        }, format='json')
        assert resp.status_code == 201

    def test_add_subtask(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Subtasks', 'key': 'SB'}, format='json')
        pk = proj.data['id']
        task = auth_client.post(f'/api/projects/{pk}/tasks/', {'title': 'S', 'status': 'TODO'}, format='json')
        resp = auth_client.post(f'/api/projects/{pk}/tasks/{task.data["id"]}/subtasks/', {
            'title': 'Checklist Item',
        }, format='json')
        assert resp.status_code == 201

    def test_my_tasks(self, auth_client):
        resp = auth_client.get('/api/tasks/my-tasks/')
        assert resp.status_code == 200

    def test_task_activity(self, auth_client):
        resp = auth_client.get('/api/tasks/activity/')
        assert resp.status_code == 200

    def test_reports(self, auth_client):
        resp = auth_client.get('/api/projects/reports/')
        assert resp.status_code == 200
        assert 'total_projects' in resp.data
        assert 'total_tasks' in resp.data
        assert 'completion_rate' in resp.data
        assert 'projects_by_status' in resp.data

    def test_global_search(self, auth_client):
        auth_client.post('/api/projects/', {'title': 'Searchable Project', 'key': 'SP'}, format='json')
        resp = auth_client.get('/api/projects/search/?q=Search')
        assert resp.status_code == 200
        assert len(resp.data['projects']) == 1
        assert resp.data['projects'][0]['title'] == 'Searchable Project'
        assert 'tasks' in resp.data

    def test_global_search_tasks(self, auth_client):
        proj = auth_client.post('/api/projects/', {'title': 'Proj Tasks', 'key': 'PT'}, format='json')
        pk = proj.data['id']
        auth_client.post(f'/api/projects/{pk}/tasks/', {'title': 'Fix search bug', 'status': 'TODO'}, format='json')
        resp = auth_client.get('/api/projects/search/?q=search')
        assert resp.status_code == 200
        assert len(resp.data['tasks']) == 1
        assert resp.data['tasks'][0]['project_title'] == 'Proj Tasks'

    def test_global_search_empty_query(self, auth_client):
        resp = auth_client.get('/api/projects/search/?q=')
        assert resp.status_code == 200
        assert resp.data['projects'] == []
        assert resp.data['tasks'] == []

    def test_global_search_short_query(self, auth_client):
        resp = auth_client.get('/api/projects/search/?q=a')
        assert resp.status_code == 200
        assert resp.data['projects'] == []
