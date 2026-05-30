import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';
import '../models/activity_log_model.dart';

class ActivityLogRepository {
  Future<List<ActivityLogModel>> getProjectActivity(String projectId) async {
    final response = await ApiClient.get('activity/?project_id=$projectId');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeJsonDecode(response.body);
      final List data = decoded is Map ? (decoded['content'] ?? []) : (decoded is List ? decoded : []);
      return data.whereType<Map<String, dynamic>>().map((json) => ActivityLogModel.fromJson(json)).toList();
    }
    throw Exception("Erreur chargement activité (${response.statusCode})");
  }

  Future<List<ActivityLogModel>> getAllActivity({int page = 0}) async {
    final response = await ApiClient.get('activity/?page=$page');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeJsonDecode(response.body);
      final List data = decoded is Map ? (decoded['content'] ?? []) : (decoded is List ? decoded : []);
      return data.whereType<Map<String, dynamic>>().map((json) => ActivityLogModel.fromJson(json)).toList();
    }
    throw Exception("Erreur chargement activité (${response.statusCode})");
  }
}
