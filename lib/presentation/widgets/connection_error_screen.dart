import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/connection_monitor.dart';

class ConnectionErrorOverlay extends StatefulWidget {
  final Widget child;

  const ConnectionErrorOverlay({super.key, required this.child});

  @override
  State<ConnectionErrorOverlay> createState() => _ConnectionErrorOverlayState();
}

class _ConnectionErrorOverlayState extends State<ConnectionErrorOverlay> {
  @override
  void initState() {
    super.initState();
    ConnectionMonitor.hasError.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    ConnectionMonitor.hasError.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!ConnectionMonitor.hasError.value) return widget.child;

    return Stack(
      children: [
        widget.child,
        Container(
          color: AppColors.background.withValues(alpha: 0.95),
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.wifiOff, size: 80, color: AppColors.danger),
                const SizedBox(height: 24),
                const Text(
                  "Problème de connexion",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Impossible d'atteindre le serveur.\nVérifiez votre connexion Internet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    ConnectionMonitor.clearError();
                  },
                  icon: const Icon(LucideIcons.refreshCw),
                  label: const Text("Réessayer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
