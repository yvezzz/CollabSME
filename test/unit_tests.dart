import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:collabsme/core/constants/app_constants.dart';
import 'package:collabsme/utils/safe_parser.dart';
import 'package:collabsme/data/models/attachment_model.dart';
import 'package:collabsme/data/models/project_analytics_model.dart';

void main() {
  group('AppColors.statusColor', () {
    test('returns correct color for TODO', () {
      expect(AppColors.statusColor('TODO'), const Color(0xFF64748B));
    });

    test('returns correct color for ACTIVE', () {
      expect(AppColors.statusColor('ACTIVE'), const Color(0xFF22C55E));
    });

    test('returns correct color for IN_PROGRESS', () {
      expect(AppColors.statusColor('IN_PROGRESS'), const Color(0xFF06B6D4));
    });

    test('returns correct color for DRAFT', () {
      expect(AppColors.statusColor('DRAFT'), const Color(0xFF9CA3AF));
    });

    test('returns correct color for PLANNING', () {
      expect(AppColors.statusColor('PLANNING'), const Color(0xFF9CA3AF));
    });

    test('returns correct color for COMPLETED', () {
      expect(AppColors.statusColor('COMPLETED'), const Color(0xFF3B82F6));
    });

    test('returns correct color for DONE', () {
      expect(AppColors.statusColor('DONE'), const Color(0xFF3B82F6));
    });

    test('returns correct color for REVIEW', () {
      expect(AppColors.statusColor('REVIEW'), const Color(0xFFF97316));
    });

    test('returns correct color for ARCHIVED', () {
      expect(AppColors.statusColor('ARCHIVED'), const Color(0xFFEF4444));
    });

    test('handles lower case', () {
      expect(AppColors.statusColor('done'), const Color(0xFF3B82F6));
    });

    test('handles mixed case', () {
      expect(AppColors.statusColor('In_Progress'), const Color(0xFF06B6D4));
    });

    test('returns default for unknown status', () {
      expect(AppColors.statusColor('UNKNOWN'), const Color(0xFF9CA3AF));
    });
  });

  group('AppColors.statusLabel', () {
    test('returns French label for TODO', () {
      expect(AppColors.statusLabel('TODO'), 'À faire');
    });

    test('returns French label for ACTIVE', () {
      expect(AppColors.statusLabel('ACTIVE'), 'Actif');
    });

    test('returns French label for IN_PROGRESS', () {
      expect(AppColors.statusLabel('IN_PROGRESS'), 'En cours');
    });

    test('returns French label for DRAFT and PLANNING', () {
      expect(AppColors.statusLabel('DRAFT'), 'Planifié');
      expect(AppColors.statusLabel('PLANNING'), 'Planifié');
    });

    test('returns French label for COMPLETED and DONE', () {
      expect(AppColors.statusLabel('COMPLETED'), 'Terminé');
      expect(AppColors.statusLabel('DONE'), 'Terminé');
    });

    test('returns French label for REVIEW', () {
      expect(AppColors.statusLabel('REVIEW'), 'En révision');
    });

    test('returns French label for ARCHIVED', () {
      expect(AppColors.statusLabel('ARCHIVED'), 'Archivé');
    });

    test('returns status as-is for unknown', () {
      expect(AppColors.statusLabel('CUSTOM'), 'CUSTOM');
    });

    test('handles lower and mixed case', () {
      expect(AppColors.statusLabel('todo'), 'À faire');
      expect(AppColors.statusLabel('In_Progress'), 'En cours');
      expect(AppColors.statusLabel('DONE'), 'Terminé');
    });
  });

  group('SafeParser.parseInt', () {
    test('returns 0 for null', () {
      expect(SafeParser.parseInt(null), 0);
    });

    test('parses int directly', () {
      expect(SafeParser.parseInt(42), 42);
    });

    test('converts double to int', () {
      expect(SafeParser.parseInt(3.14), 3);
    });

    test('parses int string', () {
      expect(SafeParser.parseInt('123'), 123);
    });

    test('returns default for invalid string', () {
      expect(SafeParser.parseInt('abc'), 0);
    });

    test('returns 0 for bool', () {
      expect(SafeParser.parseInt(true), 0);
    });

    test('uses custom default', () {
      expect(SafeParser.parseInt(null, defaultValue: -1), -1);
    });
  });

  group('SafeParser.parseDouble', () {
    test('returns 0.0 for null', () {
      expect(SafeParser.parseDouble(null), 0.0);
    });

    test('parses double directly', () {
      expect(SafeParser.parseDouble(3.14), 3.14);
    });

    test('converts int to double', () {
      expect(SafeParser.parseDouble(42), 42.0);
    });

    test('parses double string', () {
      expect(SafeParser.parseDouble('3.14'), 3.14);
    });

    test('returns default for invalid string', () {
      expect(SafeParser.parseDouble('abc'), 0.0);
    });

    test('uses custom default', () {
      expect(SafeParser.parseDouble(null, defaultValue: -1.0), -1.0);
    });
  });

  group('SafeParser.parseString', () {
    test('returns empty for null', () {
      expect(SafeParser.parseString(null), '');
    });

    test('returns string as-is', () {
      expect(SafeParser.parseString('hello'), 'hello');
    });

    test('converts int to string', () {
      expect(SafeParser.parseString(42), '42');
    });

    test('converts double to string', () {
      expect(SafeParser.parseString(3.14), '3.14');
    });

    test('converts bool to string', () {
      expect(SafeParser.parseString(true), 'true');
    });

    test('uses custom default', () {
      expect(SafeParser.parseString(null, defaultValue: 'fallback'), 'fallback');
    });
  });

  group('SafeParser.parseBool', () {
    test('returns false for null', () {
      expect(SafeParser.parseBool(null), false);
    });

    test('returns true for true', () {
      expect(SafeParser.parseBool(true), true);
    });

    test('returns false for false', () {
      expect(SafeParser.parseBool(false), false);
    });

    test('returns false for zero int', () {
      expect(SafeParser.parseBool(0), false);
    });

    test('returns true for non-zero int', () {
      expect(SafeParser.parseBool(1), true);
    });

    test('parses "true" string', () {
      expect(SafeParser.parseBool('true'), true);
    });

    test('parses "1" string', () {
      expect(SafeParser.parseBool('1'), true);
    });

    test('parses "false" string', () {
      expect(SafeParser.parseBool('false'), false);
    });

    test('returns default for invalid', () {
      expect(SafeParser.parseBool('maybe'), false);
    });
  });

  group('SafeParser.parseDateTime', () {
    test('returns null for null', () {
      expect(SafeParser.parseDateTime(null), isNull);
    });

    test('returns DateTime for DateTime', () {
      final dt = DateTime(2026, 5, 30);
      expect(SafeParser.parseDateTime(dt), dt);
    });

    test('parses ISO string', () {
      final dt = SafeParser.parseDateTime('2026-05-30T12:00:00Z');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 5);
      expect(dt.day, 30);
    });

    test('returns null for invalid string', () {
      expect(SafeParser.parseDateTime('not-a-date'), isNull);
    });
  });

  group('SafeParser.parseList', () {
    test('returns empty for null', () {
      expect(SafeParser.parseList(null, (m) => m), isEmpty);
    });

    test('parses list of maps', () {
      final data = [{'a': 1}, {'b': 2}];
      final result = SafeParser.parseList(data, (m) => m);
      expect(result.length, 2);
      expect(result[0]['a'], 1);
    });

    test('parses JSON string', () {
      final result = SafeParser.parseList('[{"a":1}]', (m) => m);
      expect(result.length, 1);
      expect(result[0]['a'], 1);
    });

    test('returns empty for invalid JSON string', () {
      expect(SafeParser.parseList('not-json', (m) => m), isEmpty);
    });
  });

  group('SafeParser.parseJsonList', () {
    test('returns empty for null', () {
      expect(SafeParser.parseJsonList(null), isEmpty);
    });

    test('parses list of strings', () {
      expect(SafeParser.parseJsonList(['a', 'b']), ['a', 'b']);
    });

    test('parses JSON string', () {
      expect(SafeParser.parseJsonList('["a","b"]'), ['a', 'b']);
    });
  });

  group('SafeParser.parseJsonMap', () {
    test('returns empty for null', () {
      expect(SafeParser.parseJsonMap(null), isEmpty);
    });

    test('parses map', () {
      expect(SafeParser.parseJsonMap({'key': 'value'}), {'key': 'value'});
    });

    test('parses JSON string', () {
      expect(SafeParser.parseJsonMap('{"key":"value"}'), {'key': 'value'});
    });
  });

  group('SafeParser.parseRawList', () {
    test('returns empty for null', () {
      expect(SafeParser.parseRawList(null), isEmpty);
    });

    test('returns list as-is', () {
      expect(SafeParser.parseRawList([1, 2, 3]), [1, 2, 3]);
    });

    test('parses JSON string', () {
      expect(SafeParser.parseRawList('[1,2,3]'), [1, 2, 3]);
    });
  });

  group('AppColors constants', () {
    test('has correct background color', () {
      expect(AppColors.background, const Color(0xFF020617));
    });

    test('has correct surface color', () {
      expect(AppColors.surface, const Color(0xFF0F172A));
    });

    test('has correct primary color', () {
      expect(AppColors.primary, const Color(0xFF6366F1));
    });

    test('has correct accent color', () {
      expect(AppColors.accent, const Color(0xFF10B981));
    });

    test('has correct danger color', () {
      expect(AppColors.danger, const Color(0xFFEF4444));
    });

    test('has correct warning color', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });

    test('has correct textSecondary color', () {
      expect(AppColors.textSecondary, const Color(0xFF94A3B8));
    });
  });

  group('AppConstants defaults', () {
    test('apiBaseUrl defaults to Railway', () {
      expect(AppConstants.apiBaseUrl, 'https://collabsme-production.up.railway.app/api/');
    });

    test('wsBaseUrl defaults to Railway WebSocket', () {
      expect(AppConstants.wsBaseUrl, 'wss://collabsme-production.up.railway.app/');
    });
  });

  group('AttachmentModel null handling', () {
    test('file_size null does not crash', () {
      final json = {'id': 'a1', 'file': '', 'uploaded_at': '2026-05-16T12:00:00Z'};
      final a = AttachmentModel.fromJson(json);
      expect(a.fileSize, 0);
    });

    test('file_size as int parsed correctly', () {
      final json = {'id': 'a1', 'file_size': 2048, 'file': '', 'uploaded_at': '2026-05-16T12:00:00Z'};
      final a = AttachmentModel.fromJson(json);
      expect(a.fileSize, 2048);
    });
  });

  group('ProjectAnalyticsModel null handling', () {
    test('completion_rate null does not crash', () {
      final json = <String, dynamic>{};
      final a = ProjectAnalyticsModel.fromJson(json);
      expect(a.completionRate, 0.0);
    });
  });
}
