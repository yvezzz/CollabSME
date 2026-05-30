import 'dart:convert';

class SafeParser {
  static List<T> parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data == null) return [];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((e) => fromJson(e)).toList();
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().map((e) => fromJson(e)).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  static String parseString(dynamic data, {String defaultValue = ''}) {
    if (data == null) return defaultValue;
    if (data is String) return data;
    if (data is num || data is bool) return data.toString();
    return defaultValue;
  }

  static int parseInt(dynamic data, {int defaultValue = 0}) {
    if (data == null) return defaultValue;
    if (data is int) return data;
    if (data is double) return data.toInt();
    if (data is String) return int.tryParse(data) ?? defaultValue;
    return defaultValue;
  }

  static double parseDouble(dynamic data, {double defaultValue = 0.0}) {
    if (data == null) return defaultValue;
    if (data is double) return data;
    if (data is int) return data.toDouble();
    if (data is String) return double.tryParse(data) ?? defaultValue;
    return defaultValue;
  }

  static bool parseBool(dynamic data, {bool defaultValue = false}) {
    if (data is bool) return data;
    if (data is int) return data != 0;
    if (data is String) {
      if (data == 'true' || data == '1') return true;
      if (data == 'false' || data == '0') return false;
    }
    return defaultValue;
  }

  static DateTime? parseDateTime(dynamic data) {
    if (data == null) return null;
    if (data is DateTime) return data;
    if (data is String) return DateTime.tryParse(data);
    return null;
  }

  static dynamic safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? safeDecodeMap(String body) {
    final result = safeJsonDecode(body);
    if (result is Map<String, dynamic>) return result;
    return null;
  }

  static List<dynamic>? safeDecodeList(String body) {
    final result = safeJsonDecode(body);
    if (result is List<dynamic>) return result;
    return null;
  }

  static List<String> parseJsonList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.whereType<String>().toList();
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded.whereType<String>().toList();
      } catch (_) {}
    }
    return [];
  }

  static Map<String, dynamic> parseJsonMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  static List<dynamic> parseRawList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }
}
