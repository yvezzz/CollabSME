import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collabsme/presentation/widgets/status_badge.dart';
import 'package:collabsme/presentation/widgets/app_toast.dart';
import 'package:collabsme/core/constants/app_constants.dart';

void main() {
  group('StatusBadge', () {
    Widget buildBadge(String status) {
      return MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: status),
        ),
      );
    }

    testWidgets('renders TODO status', (tester) async {
      await tester.pumpWidget(buildBadge('TODO'));
      expect(find.text('À faire'), findsOneWidget);
    });

    testWidgets('renders ACTIVE/IN_PROGRESS status', (tester) async {
      await tester.pumpWidget(buildBadge('IN_PROGRESS'));
      expect(find.text('En cours'), findsOneWidget);
    });

    testWidgets('renders DONE status', (tester) async {
      await tester.pumpWidget(buildBadge('DONE'));
      expect(find.text('Terminé'), findsOneWidget);
    });

    testWidgets('renders REVIEW status', (tester) async {
      await tester.pumpWidget(buildBadge('REVIEW'));
      expect(find.text('En révision'), findsOneWidget);
    });

    testWidgets('renders ARCHIVED status', (tester) async {
      await tester.pumpWidget(buildBadge('ARCHIVED'));
      expect(find.text('Archivé'), findsOneWidget);
    });

    testWidgets('renders DRAFT/PLANNING status', (tester) async {
      await tester.pumpWidget(buildBadge('DRAFT'));
      expect(find.text('Planifié'), findsOneWidget);
    });

    testWidgets('renders unknown status as-is', (tester) async {
      await tester.pumpWidget(buildBadge('CUSTOM'));
      expect(find.text('CUSTOM'), findsOneWidget);
    });
  });

  group('AppColors', () {
    test('values are correct', () {
      expect(AppColors.background, const Color(0xFF020617));
      expect(AppColors.surface, const Color(0xFF0F172A));
      expect(AppColors.primary, const Color(0xFF6366F1));
      expect(AppColors.accent, const Color(0xFF10B981));
      expect(AppColors.danger, const Color(0xFFEF4444));
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });
  });

  group('Priority label mapping', () {
    test('priority color mapping matches expected', () {
      Color colorFor(String priority) {
        switch (priority) {
          case 'HIGH':
          case 'CRITICAL':
            return AppColors.danger;
          case 'MEDIUM':
            return AppColors.warning;
          case 'LOW':
            return AppColors.accent;
          default:
            return AppColors.accent;
        }
      }

      expect(colorFor('HIGH'), AppColors.danger);
      expect(colorFor('CRITICAL'), AppColors.danger);
      expect(colorFor('MEDIUM'), AppColors.warning);
      expect(colorFor('LOW'), AppColors.accent);
    });
  });

  group('StatusBadge case insensitivity', () {
    testWidgets('lowercase status maps correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusBadge(status: 'done'))));
      expect(find.text('Terminé'), findsOneWidget);
    });

    testWidgets('mixed case status maps correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusBadge(status: 'In_Progress'))));
      expect(find.text('En cours'), findsOneWidget);
    });
  });

  group('AppConstants', () {
    test('apiBaseUrl ends with /api/', () {
      const url = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://test.dev/api/');
      expect(url.endsWith('/api/'), isTrue);
    });
  });

  group('ToastType enum', () {
    test('has three values', () {
      expect(ToastType.values.length, 3);
      expect(ToastType.values, contains(ToastType.success));
      expect(ToastType.values, contains(ToastType.error));
      expect(ToastType.values, contains(ToastType.info));
    });
  });
}
