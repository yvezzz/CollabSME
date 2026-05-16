import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/network/api_client.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider = Provider(
  (ref) => NotificationRepository(),
);

final notificationListProvider =
    StateNotifierProvider<
      NotificationListNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      final repository = ref.watch(notificationRepositoryProvider);
      final authState = ref.watch(authStateProvider);

      final notifier = NotificationListNotifier(repository);

      authState.whenData((user) async {
        if (user != null) {
          final token = await ApiClient.getToken();
          if (token != null) {
            notifier.initWebSocket(token);
          }
        }
      });

      return notifier;
    });

class NotificationListNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _repository;
  NotificationService? _wsService;
  Timer? _pollTimer;
  bool _isPolling = false;

  NotificationListNotifier(this._repository)
    : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  void initWebSocket(String token) {
    _wsService?.disconnect();
    _wsService = NotificationService(
      onNotificationReceived: (notification) {
        addNotification(notification);
      },
      getToken: () async => await ApiClient.getToken(),
      onFallbackToPolling: _startPolling,
    );
    _wsService!.connect();
  }

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    debugPrint("Starting HTTP polling fallback for notifications (every 30s)");
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await fetchNotificationsSilent();
    });
  }

  Future<void> fetchNotificationsSilent() async {
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsService?.disconnect();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void addNotification(NotificationModel notification) {
    state.whenData((notifications) {
      state = AsyncValue.data([notification, ...notifications]);
    });
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) {
            if (n.id == id) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList(),
        );
      });
    } catch (e) {
      debugPrint("markAsRead error: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) => n.copyWith(isRead: true)).toList(),
        );
      });
    } catch (e) {
      debugPrint("markAllAsRead error: $e");
    }
  }
}

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  try {
    return await repository.getUnreadCount();
  } catch (_) {
    return 0;
  }
});
