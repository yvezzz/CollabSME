import 'dart:convert';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  /// Récupérer le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    final response = await ApiClient.get('notifications/unread_count/');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['unread_count'] ?? 0;
    }
    return 0;
  }

  /// Récupérer les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications() async {
    final response = await ApiClient.get('notifications/');
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final List data = decoded is Map ? (decoded['results'] ?? []) : decoded;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des notifications");
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String id) async {
    final response = await ApiClient.post('notifications/$id/mark_as_read/', {});
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du marquage de la notification");
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    final response = await ApiClient.post('notifications/mark_all_as_read/', {});
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du marquage global");
    }
  }
}
