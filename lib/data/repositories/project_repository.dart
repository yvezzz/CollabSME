import 'dart:convert';
import '../models/project_model.dart';
import '../models/dashboard_stats.dart';
import '../../core/network/api_client.dart';

class ProjectRepository {
  /// Récupérer les statistiques globales pour le tableau de bord
  Future<DashboardStats> getDashboardStats() async {
    final response = await ApiClient.get('projects/dashboard/stats/');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return DashboardStats(
        totalProjects: json['total_projects'],
        activeTasks: json['active_tasks'],
        teamMembers: json['total_members'],
      );
    }
    return DashboardStats.empty();
  }

  /// Récupérer la liste des projets de l'entreprise
  Future<Map<String, dynamic>> getProjects({int page = 1, String search = ''}) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (search.isNotEmpty) params['search'] = search;
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final response = await ApiClient.get('projects/?$query');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data is Map ? (data['results'] ?? []) : data;
        final count = data is Map ? (data['count'] ?? results.length) : results.length;
        return {
          'projects': results.map((json) => ProjectModel.fromJson(json)).toList(),
          'count': count,
        };
      } else {
        throw Exception(
          "Erreur lors de la récupération des projets (${response.statusCode})",
        );
      }
    } catch (e) {
      throw Exception("Erreur réseau : $e");
    }
  }

  /// Créer un nouveau projet
  Future<ProjectModel> createProject({
    required String title,
    required String description,
    String? key,
    String status = 'DRAFT',
    String priority = 'MEDIUM',
    double? budget,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
      };
      if (key != null) data['key'] = key;
      if (budget != null) data['budget'] = budget;

      final response = await ApiClient.post('projects/', data);

      if (response.statusCode == 201) {
        return ProjectModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Impossible de créer le projet : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur réseau : $e");
    }
  }

  /// Récupérer un projet par son ID
  Future<ProjectModel> getProject(String id) async {
    try {
      final response = await ApiClient.get('projects/$id/');
      if (response.statusCode == 200) {
        return ProjectModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Impossible de récupérer le projet");
      }
    } catch (e) {
      throw Exception("Erreur réseau : $e");
    }
  }

  /// Supprimer un projet (archivage côté backend)
  Future<void> deleteProject(String id) async {
    final response = await ApiClient.delete('projects/$id/');
    if (response.statusCode != 204) {
      throw Exception("Erreur lors de la suppression");
    }
  }

  /// Mettre à jour un projet (PATCH partiel)
  Future<ProjectModel> updateProject(
    String id, {
    String? title,
    String? description,
    String? key,
    String? status,
    String? priority,
    double? budget,
    String? startDate,
    String? endDate,
    List<String>? tags,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (key != null) data['key'] = key;
      if (status != null) data['status'] = status;
      if (priority != null) data['priority'] = priority;
      if (budget != null) data['budget'] = budget;
      if (startDate != null) data['start_date'] = startDate;
      if (endDate != null) data['end_date'] = endDate;
      if (tags != null) data['tags'] = tags;

      final response = await ApiClient.patch('projects/$id/', data);
      if (response.statusCode == 200) {
        return ProjectModel.fromJson(jsonDecode(response.body));
      }
      throw Exception("Erreur lors de la mise à jour du projet");
    } catch (e) {
      throw Exception("Erreur réseau : $e");
    }
  }

  /// Changer le statut d'un projet (activate / validate / archive)
  Future<void> updateProjectStatus(String id, String action) async {
    final response = await ApiClient.post('projects/$id/$action/', {});
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de statut");
    }
  }
}
