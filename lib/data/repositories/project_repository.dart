import '../models/project_model.dart';
import '../models/dashboard_stats.dart';
import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';

class ProjectRepository {
  Future<DashboardStats> getDashboardStats() async {
    final response = await ApiClient.get('projects/dashboard/stats/');
    if (response.statusCode == 200) {
      final json = SafeParser.safeDecodeMap(response.body);
      if (json == null) return DashboardStats.empty();
      return DashboardStats(
        totalProjects: SafeParser.parseInt(json['total_projects']),
        activeTasks: SafeParser.parseInt(json['active_tasks']),
        teamMembers: SafeParser.parseInt(json['total_members']),
      );
    }
    return DashboardStats.empty();
  }

  Future<Map<String, dynamic>> getProjects({int page = 1, String search = ''}) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (search.isNotEmpty) params['search'] = search;
      final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final response = await ApiClient.get('projects/?$query');

      if (response.statusCode == 200) {
        final decoded = SafeParser.safeJsonDecode(response.body);
        final List results = decoded is Map ? (decoded['results'] is List ? decoded['results'] : []) : (decoded is List ? decoded : []);
        final int total = decoded is Map ? (SafeParser.parseInt(decoded['count']) != 0 ? SafeParser.parseInt(decoded['count']) : results.length) : results.length;
        return {
          'projects': results.map((json) => json is Map<String, dynamic> ? ProjectModel.fromJson(json) : ProjectModel.fromJson({})).toList(),
          'count': total,
        };
      }
      throw Exception("Erreur lors de la récupération des projets (${response.statusCode})");
    } catch (e) {
      if (e is Exception && e.toString().contains('Erreur lors')) rethrow;
      throw Exception("Erreur lors de la récupération des projets : $e");
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    final response = await ApiClient.get('projects/templates/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeDecodeList(response.body);
      if (decoded == null) return [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<ProjectModel> createFromTemplate(String templateId, String title) async {
    final response = await ApiClient.post('projects/templates/create-from-template/', {
      'template_id': templateId,
      'title': title,
    });
    if (response.statusCode == 201) {
      final json = SafeParser.safeDecodeMap(response.body) ?? {};
      return ProjectModel.fromJson(json);
    }
    throw Exception("Impossible de créer le projet depuis le template (${response.statusCode})");
  }

  Future<ProjectModel> createProject({
    required String title,
    required String description,
    String? key,
    String status = 'DRAFT',
    String priority = 'MEDIUM',
    double? budget,
    String? startDate,
    String? endDate,
    int? leadId,
    List<int>? memberIds,
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
      if (startDate != null) data['startDate'] = startDate;
      if (endDate != null) data['endDate'] = endDate;
      if (leadId != null) data['lead_id'] = leadId;
      if (memberIds != null && memberIds.isNotEmpty) data['member_ids'] = memberIds;

      final response = await ApiClient.post('projects/', data);
      if (response.statusCode == 201) {
        final body = SafeParser.safeDecodeMap(response.body);
        if (body == null) throw Exception("Réponse inattendue du serveur");
        return ProjectModel.fromJson(body);
      }
      throw Exception("Impossible de créer le projet (${response.statusCode})");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Erreur lors de la création du projet : $e");
    }
  }

  Future<ProjectModel> getProject(String id) async {
    try {
      final response = await ApiClient.get('projects/$id/');
      if (response.statusCode == 200) {
        final json = SafeParser.safeDecodeMap(response.body) ?? {};
        return ProjectModel.fromJson(json);
      }
      throw Exception("Impossible de récupérer le projet (${response.statusCode})");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Erreur lors du chargement du projet : $e");
    }
  }

  Future<void> deleteProject(String id) async {
    final response = await ApiClient.delete('projects/$id/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression (${response.statusCode})");
    }
  }

  Future<ProjectModel> updateProject(String id, {String? title, String? description, String? key, String? status, String? priority, double? budget, String? startDate, String? endDate, List<String>? tags}) async {
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
        final json = SafeParser.safeDecodeMap(response.body) ?? {};
        return ProjectModel.fromJson(json);
      }
      throw Exception("Erreur lors de la mise à jour du projet (${response.statusCode})");
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Erreur lors de la mise à jour du projet : $e");
    }
  }

  Future<void> updateProjectStatus(String id, String action) async {
    final response = await ApiClient.post('projects/$id/$action/', {});
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de statut (${response.statusCode})");
    }
  }
}
