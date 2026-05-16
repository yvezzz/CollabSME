import 'dart:convert';
import '../models/activity_log_model.dart';
import '../../core/network/api_client.dart';

class ActivityLogRepository {
  /// Récupérer l'historique d'un projet
  Future<List<ActivityLogModel>> getProjectActivity(String projectId) async {
    final response = await ApiClient.get('activity/?project_id=$projectId');

    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final List data = decoded is Map ? (decoded['results'] ?? []) : decoded;
      return data.map((json) => ActivityLogModel.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération de l'historique");
    }
  }

  /// Récupérer l'activité globale de l'entreprise (Admin)
  Future<List<ActivityLogModel>> getCompanyActivity() async {
    final response = await ApiClient.get('activity/');
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final List data = decoded is Map ? (decoded['results'] ?? []) : decoded;
      return data.map((json) => ActivityLogModel.fromJson(json)).toList();
    }
    throw Exception("Erreur lors de la récupération de l'activité");
  }
}
