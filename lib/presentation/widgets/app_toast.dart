import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

enum ToastType { success, error, info }

class AppToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    try { _current?.remove(); } catch (_) {}

    final overlay = Overlay.of(context);
    final isError = type == ToastType.error;
    final isSuccess = type == ToastType.success;

    final Color bgColor = AppColors.primary;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline : isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _current?.remove(),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _current = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      try { _current?.remove(); } catch (_) {}
      _current = null;
    });
  }
}
