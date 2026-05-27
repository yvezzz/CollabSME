import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/task_model.dart';
import '../../core/network/api_client.dart';

class TaskRepository {
  /// Lister les tâches d'un projet spécifique
  Future<List<TaskModel>> getTasks(String projectId) async {
    final response = await ApiClient.get('projects/$projectId/tasks/');

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final List data = decoded is Map ? (decoded['results'] ?? []) : decoded;
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des tâches");
    }
  }

  /// Récupérer les tâches assignées à l'utilisateur actuel
  Future<List<TaskModel>> getUserTasks() async {
    final response = await ApiClient.get('tasks/my-tasks/');
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final List data = decoded is Map ? (decoded['results'] ?? []) : decoded;
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération de mes tâches");
    }
  }

  /// Créer une tâche
  Future<TaskModel> createTask(String projectId, Map<String, dynamic> data) async {
    final response = await ApiClient.post('projects/$projectId/tasks/', data);
    if (response.statusCode == 201) {
      return TaskModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Impossible de créer la tâche (${response.statusCode})");
  }

  /// Met à jour le statut via l'action dédiée (assigné / lead)
  Future<void> updateTaskStatus(String projectId, String taskId, String newStatus) async {
    final response = await ApiClient.patch(
      'projects/$projectId/tasks/$taskId/status/',
      {'status': newStatus},
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de statut (${response.statusCode})");
    }
  }

  /// Réordonnancement Kanban (même colonne ou autre) — aligné sur le backend Spring Boot
  Future<void> reorderTask(
    String projectId,
    String taskId,
    String newStatus,
    int newOrder,
  ) async {
    final response = await ApiClient.patch(
      'projects/$projectId/tasks/reorder/',
      {
        'task_id': taskId,
        'new_status': newStatus,
        'new_order': newOrder,
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur réordonnancement (${response.statusCode})");
    }
  }

  /// Récupérer une tâche unique avec tous les détails (commentaires, sous-tâches, pièces jointes)
  Future<TaskModel> getTask(String projectId, String taskId) async {
    final response = await ApiClient.get('projects/$projectId/tasks/$taskId/');
    if (response.statusCode == 200) {
      return TaskModel.fromJson(jsonDecode(response.body));
    }
    throw Exception("Erreur lors du chargement de la tâche (${response.statusCode})");
  }

  /// Ajouter un commentaire (route imbriquée projet → tâche)
  Future<void> addComment(String projectId, String taskId, String content) async {
    final response = await ApiClient.post(
      'projects/$projectId/tasks/$taskId/comments/',
      {'content': content},
    );
    if (response.statusCode != 201) {
      throw Exception("Impossible d'ajouter le commentaire (${response.statusCode})");
    }
  }

  /// Créer une sous-tâche (checklist)
  Future<void> createSubtask(String projectId, String taskId, String title) async {
    final response = await ApiClient.post(
      'projects/$projectId/tasks/$taskId/subtasks/',
      {'title': title},
    );
    if (response.statusCode != 201) {
      throw Exception("Impossible de créer la sous-tâche (${response.statusCode})");
    }
  }

  /// Uploader une pièce jointe
  Future<Map<String, dynamic>> uploadAttachment(String projectId, String taskId, String filePath, String fileName) async {
    final file = await http.MultipartFile.fromPath('file', filePath, filename: fileName);
    final response = await ApiClient.postMultipart(
      'projects/$projectId/tasks/$taskId/attachments/',
      files: [file],
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception("Erreur lors de l'upload (${response.statusCode})");
  }

  /// Mettre à jour une sous-tâche (checklist)
  Future<void> patchSubtaskChecklist(
    String projectId,
    String taskId,
    String subTaskId, {
    required bool isCompleted,
  }) async {
    final response = await ApiClient.patch(
      'projects/$projectId/tasks/$taskId/subtasks/$subTaskId/',
      {'is_completed': isCompleted},
    );
    if (response.statusCode != 200) {
      throw Exception("Sous-tâche non mise à jour (${response.statusCode})");
    }
  }

  /// Récupérer les stats d'activité (tâches finies)
  Future<List<Map<String, dynamic>>> getActivityStats() async {
    final response = await ApiClient.get('tasks/activity/');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception("Impossible de charger les statistiques d'activité");
  }
}
