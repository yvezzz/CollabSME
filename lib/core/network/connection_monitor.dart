import 'package:flutter/foundation.dart';

class ConnectionMonitor {
  static final hasError = ValueNotifier<bool>(false);

  static void reportError() {
    hasError.value = true;
  }

  static void clearError() {
    hasError.value = false;
  }
}
