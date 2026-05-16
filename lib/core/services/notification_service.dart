import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import '../../data/models/notification_model.dart';

class NotificationService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _connecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  final Function(NotificationModel) onNotificationReceived;
  final Future<String?> Function() getToken;
  final VoidCallback? onFallbackToPolling;

  NotificationService({
    required this.onNotificationReceived,
    required this.getToken,
    this.onFallbackToPolling,
  });

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected || _connecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onFallbackToPolling?.call();
      return;
    }
    _connecting = true;
    _shouldReconnect = true;

    try {
      final token = await getToken();
      if (token == null) {
        _connecting = false;
        return;
      }

      final wsUrl = Uri.parse(
        "${AppConstants.wsBaseUrl}ws/notifications/?token=$token",
      );
      debugPrint("WS connecting with token: ${token.substring(0, 10)}...");

      final ws = await WebSocket.connect(wsUrl.toString()).timeout(
        const Duration(seconds: 10),
      );
      _channel = IOWebSocketChannel(ws);
      _isConnected = true;
      _connecting = false;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (data['type'] == 'notification') {
            final notification = NotificationModel.fromJson(
              data['notification'],
            );
            onNotificationReceived(notification);
          }
        },
        onDone: () {
          _isConnected = false;
          _connecting = false;
          _channel = null;
          if (_shouldReconnect) {
            _reconnectAttempts++;
            final delay = Duration(
              seconds: (_reconnectAttempts * 5).clamp(5, 60),
            );
            Future.delayed(delay, () => connect());
          } else {
            onFallbackToPolling?.call();
          }
        },
        onError: (error) {
          _isConnected = false;
          _connecting = false;
          _channel = null;
          if (_shouldReconnect) {
            _reconnectAttempts++;
            final delay = Duration(
              seconds: (_reconnectAttempts * 5).clamp(5, 60),
            );
            Future.delayed(delay, () => connect());
          } else {
            onFallbackToPolling?.call();
          }
        },
      );
    } catch (e) {
      _isConnected = false;
      _connecting = false;
      onFallbackToPolling?.call();
    }
  }

  void stop() {
    _shouldReconnect = false;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connecting = false;
  }

  void disconnect() {
    stop();
  }
}
