import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  Future<int> getUnreadCount() async {
    final response = await ApiClient.get('notifications/unread_count/');
    if (response.statusCode == 200) {
      final json = SafeParser.safeDecodeMap(response.body);
      return SafeParser.parseInt(json?['unread_count']);
    }
    return 0;
  }

  Future<List<NotificationModel>> getNotifications() async {
    final response = await ApiClient.get('notifications/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeJsonDecode(response.body);
      final List data = decoded is Map ? (decoded['content'] ?? decoded['results'] ?? []) : (decoded is List ? decoded : []);
      return data.map((json) => json is Map<String, dynamic> ? NotificationModel.fromJson(json) : NotificationModel.fromJson({})).toList();
    }
    throw Exception("Erreur lors de la récupération des notifications (${response.statusCode})");
  }

  Future<void> markAsRead(String id) async {
    final response = await ApiClient.post('notifications/$id/mark_as_read/', {});
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du marquage de la notification (${response.statusCode})");
    }
  }

  Future<void> markAllAsRead() async {
    final response = await ApiClient.post('notifications/mark_all_as_read/', {});
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du marquage global (${response.statusCode})");
    }
  }
}
