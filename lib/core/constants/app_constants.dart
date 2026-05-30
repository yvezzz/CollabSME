import 'package:flutter/material.dart';

/// Centralisation des couleurs pour garantir une cohérence visuelle (Design System)
class AppColors {
  static const Color background = Color(0xFF020617);
  static const Color surface = Color(0xFF0F172A);
  static const Color card = Color(0xFF1E293B);
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color accent = Color(0xFF10B981);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

    // Dégradé utilisé pour les logos et les éléments d'importance
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'TODO':
        return Color(0xFF64748B);
      case 'ACTIVE':
        return Color(0xFF22C55E);
      case 'IN_PROGRESS':
        return Color(0xFF06B6D4);
      case 'DRAFT':
      case 'PLANNING':
        return Color(0xFF9CA3AF);
      case 'COMPLETED':
      case 'DONE':
        return Color(0xFF3B82F6);
      case 'REVIEW':
        return Color(0xFFF97316);
      case 'ARCHIVED':
        return Color(0xFFEF4444);
      default:
        return Color(0xFF9CA3AF);
    }
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'TODO':
        return "À faire";
      case 'ACTIVE':
        return "Actif";
      case 'IN_PROGRESS':
        return "En cours";
      case 'DRAFT':
      case 'PLANNING':
        return "Brouillon";
      case 'COMPLETED':
      case 'DONE':
        return "Terminé";
      case 'REVIEW':
        return "En révision";
      case 'ARCHIVED':
        return "Archivé";
      default:
        return status;
    }
  }
}



/// Constantes globales de l'application
class AppConstants {
  /// Surcharge au build : `flutter run --dart-define=API_BASE_URL=http://192.168.1.xxx:8000/api/`
  /// (appareil physique → backend Spring Boot sur la machine hôte). Même principe pour [wsBaseUrl].
  /// Android émulé : http://10.0.2.2:8000/api/
  /// iOS émulé : http://127.0.0.1:8000/api/
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://unconvoluted-prepreference-jeraldine.ngrok-free.dev/api/',
  );
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://unconvoluted-prepreference-jeraldine.ngrok-free.dev/',
  );
}
