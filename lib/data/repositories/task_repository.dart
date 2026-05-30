import 'package:http/http.dart' as http;

import '../models/task_model.dart';
import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';

class TaskRepository {
  Future<List<TaskModel>> getTasks(String projectId) async {
    final response = await ApiClient.get('projects/$projectId/tasks/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeJsonDecode(response.body);
      final List data = decoded is Map ? (decoded['content'] is List ? decoded['content'] : []) : (decoded is List ? decoded : []);
      return data.map((json) => json is Map<String, dynamic> ? TaskModel.fromJson(json) : TaskModel.fromJson({})).toList();
    }
    throw Exception("Erreur lors de la récupération des tâches (${response.statusCode})");
  }

  Future<List<TaskModel>> getUserTasks() async {
    final response = await ApiClient.get('tasks/my-tasks/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeJsonDecode(response.body);
      final List data = decoded is Map ? (decoded['content'] is List ? decoded['content'] : []) : (decoded is List ? decoded : []);
      return data.map((json) => json is Map<String, dynamic> ? TaskModel.fromJson(json) : TaskModel.fromJson({})).toList();
    }
    throw Exception("Erreur lors de la récupération de mes tâches (${response.statusCode})");
  }

  Future<TaskModel> createTask(String projectId, Map<String, dynamic> data) async {
    final response = await ApiClient.post('projects/$projectId/tasks/', data);
    if (response.statusCode == 201) {
      final json = SafeParser.safeDecodeMap(response.body) ?? {};
      return TaskModel.fromJson(json);
    }
    throw Exception("Impossible de créer la tâche (${response.statusCode})");
  }

  Future<void> updateTaskStatus(String projectId, String taskId, String newStatus) async {
    final response = await ApiClient.patch(
      'projects/$projectId/tasks/$taskId/status/',
      {'status': newStatus},
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de statut (${response.statusCode})");
    }
  }

  Future<void> reorderTask(String projectId, String taskId, String newStatus, int newOrder) async {
    final response = await ApiClient.patch(
      'projects/$projectId/tasks/reorder/',
      {'task_id': taskId, 'new_status': newStatus, 'new_order': newOrder},
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur réordonnancement (${response.statusCode})");
    }
  }

  Future<TaskModel> getTask(String projectId, String taskId) async {
    final response = await ApiClient.get('projects/$projectId/tasks/$taskId/');
    if (response.statusCode == 200) {
      final json = SafeParser.safeDecodeMap(response.body) ?? {};
      return TaskModel.fromJson(json);
    }
    throw Exception("Erreur lors du chargement de la tâche (${response.statusCode})");
  }

  Future<void> addComment(String projectId, String taskId, String content) async {
    final response = await ApiClient.post(
      'projects/$projectId/tasks/$taskId/comments/',
      {'content': content},
    );
    if (response.statusCode != 201) {
      throw Exception("Impossible d'ajouter le commentaire (${response.statusCode})");
    }
  }

  Future<void> createSubtask(String projectId, String taskId, String title) async {
    final response = await ApiClient.post(
      'projects/$projectId/tasks/$taskId/subtasks/',
      {'title': title},
    );
    if (response.statusCode != 201) {
      throw Exception("Impossible de créer la sous-tâche (${response.statusCode})");
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(String projectId, String taskId, String filePath, String fileName) async {
    final file = await http.MultipartFile.fromPath('file', filePath, filename: fileName);
    final response = await ApiClient.postMultipart(
      'projects/$projectId/tasks/$taskId/attachments/',
      files: [file],
    );
    if (response.statusCode == 201) {
      return SafeParser.parseJsonMap(response.body);
    }
    throw Exception("Erreur lors de l'upload (${response.statusCode})");
  }

  Future<void> patchSubtaskChecklist(String projectId, String taskId, String subTaskId, {required bool isCompleted}) async {
    final response = await ApiClient.patch(
      'projects/$projectId/tasks/$taskId/subtasks/$subTaskId/',
      {'is_completed': isCompleted},
    );
    if (response.statusCode != 200) {
      throw Exception("Sous-tâche non mise à jour (${response.statusCode})");
    }
  }

  Future<TaskModel> updateTask(String projectId, String taskId, Map<String, dynamic> data) async {
    final response = await ApiClient.put('projects/$projectId/tasks/$taskId/', data);
    if (response.statusCode == 200) {
      final json = SafeParser.safeDecodeMap(response.body) ?? {};
      return TaskModel.fromJson(json);
    }
    throw Exception("Impossible de modifier la tâche (${response.statusCode})");
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    final response = await ApiClient.delete('projects/$projectId/tasks/$taskId/');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Impossible de supprimer la tâche (${response.statusCode})");
    }
  }

  Future<List<Map<String, dynamic>>> getActivityStats() async {
    final response = await ApiClient.get('tasks/activity/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeDecodeList(response.body);
      if (decoded == null) return [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    throw Exception("Impossible de charger les statistiques d'activité (${response.statusCode})");
  }
}
