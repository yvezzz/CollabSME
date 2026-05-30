import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'connection_monitor.dart';
import '../../utils/safe_parser.dart';

typedef _AuthedRequest =
    Future<http.Response> Function(Map<String, String> headers);

/// Service centralisé pour la communication avec le backend Spring Boot
/// Gère les requêtes HTTP et l'injection de token JWT
class ApiClient {
  static final bool _isWeb = kIsWeb;
  static late final SharedPreferences _prefs;

  static const String _tokenKey = 'collabsme_access_token';
  static const String _refreshKey = 'collabsme_refresh_token';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Callback déclenché quand les tokens sont supprimés (session expirée)
  static void Function()? onSessionExpired;

  static Future<bool>? _ongoingRefresh;

  static Future<String?> _read(String key) async => _isWeb ? _prefs.getString(key) : await const FlutterSecureStorage().read(key: key);
  static Future<void> _write(String key, String value) async {
    if (_isWeb) {
      await _prefs.setString(key, value);
    } else {
      await const FlutterSecureStorage().write(key: key, value: value);
    }
  }
  static Future<void> _delete(String key) async {
    if (_isWeb) {
      await _prefs.remove(key);
    } else {
      await const FlutterSecureStorage().delete(key: key);
    }
  }

  static Future<bool> _refreshAccessTokenIfPossible() {
    _ongoingRefresh ??= _performTokenRefresh().whenComplete(() {
      _ongoingRefresh = null;
    });
    return _ongoingRefresh!;
  }

  static Future<bool> _performTokenRefresh() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final url = Uri.parse('${AppConstants.apiBaseUrl}auth/token/refresh/');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        try {
          final data = SafeParser.safeDecodeMap(response.body);
          if (data == null) return false;
          final access = SafeParser.parseString(data['access']);
          if (access.isNotEmpty) await saveToken(access);
          final newRefresh = data['refresh'];
          if (newRefresh is String && newRefresh.isNotEmpty) {
            await saveRefreshToken(newRefresh);
          }
          return true;
        } catch (_) {
          return false;
        }
      }
      await removeToken();
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _withAuthRetry(
    _AuthedRequest send, {
    required bool authenticated,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    try {
      var headers = await _getHeaders(authenticated: authenticated);
      var response = await send(headers).timeout(timeout);
      if (authenticated &&
          (response.statusCode == 401 || response.statusCode == 403) &&
          await getRefreshToken() != null) {
        final refreshed = await _refreshAccessTokenIfPossible();
        if (refreshed) {
          headers = await _getHeaders(authenticated: true);
          response = await send(headers).timeout(timeout);
        }
      }
      return response;
    } on TimeoutException catch (_) {
      ConnectionMonitor.reportError();
      rethrow;
    } on SocketException catch (_) {
      ConnectionMonitor.reportError();
      rethrow;
    } on HttpException catch (_) {
      ConnectionMonitor.reportError();
      rethrow;
    } catch (_) {
      ConnectionMonitor.reportError();
      rethrow;
    }
  }

  /// Obtient les headers globaux requis pour toutes les requêtes
  static Future<Map<String, String>> _getHeaders({
    bool authenticated = true,
  }) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (authenticated) {
      // Ajoute le token JWT de l'utilisateur s'il est connecté
      final token = await _read(_tokenKey);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Sauvegarde du token d'authentification après le login
  static Future<void> saveToken(String token) async {
    await _write(_tokenKey, token);
  }

  /// Sauvegarde du token de rafraîchissement
  static Future<void> saveRefreshToken(String token) async {
    await _write(_refreshKey, token);
  }

  /// Suppression des tokens lors de la déconnexion
  static Future<void> removeToken() async {
    await _delete(_tokenKey);
    await _delete(_refreshKey);
    onSessionExpired?.call();
  }

  /// Récupération du token d'accès
  static Future<String?> getToken() async {
    return await _read(_tokenKey);
  }

  /// Récupération du token de rafraîchissement
  static Future<String?> getRefreshToken() async {
    return await _read(_refreshKey);
  }

  /// Suppression du token de rafraîchissement spécifiquement
  static Future<void> removeRefreshToken() async {
    await _delete(_refreshKey);
  }

  /// Requête GET (Exemple: Récupérer les projets `api/projects/`)
  static Future<http.Response> get(
    String endpoint, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    return _withAuthRetry(
      (h) => http.get(url, headers: h),
      authenticated: authenticated,
    );
  }

  /// Requête POST (Exemple: Connexion `auth/login/` ou créer une Tâche)
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    final encoded = jsonEncode(body);
    return _withAuthRetry(
      (h) => http.post(url, headers: h, body: encoded),
      authenticated: authenticated,
    );
  }

  /// Requête PUT (Exemple: Mettre à jour le statut d'une tâche)
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    final encoded = jsonEncode(body);
    return _withAuthRetry(
      (h) => http.put(url, headers: h, body: encoded),
      authenticated: authenticated,
    );
  }

  /// Requête PATCH (Exemple: Mise à jour partielle d'une tâche)
  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    final encoded = jsonEncode(body);
    return _withAuthRetry(
      (h) => http.patch(url, headers: h, body: encoded),
      authenticated: authenticated,
    );
  }

  /// Requête DELETE (Exemple: Supprimer un projet)
  static Future<http.Response> delete(
    String endpoint, {
    bool authenticated = true,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    return _withAuthRetry(
      (h) => http.delete(url, headers: h),
      authenticated: authenticated,
    );
  }

  /// Upload multipart (fichier + données), utilisé pour les pièces jointes
  static Future<http.Response> postMultipart(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String> fields = const {},
    bool authenticated = true,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);

    if (authenticated) {
      final token = await _read(_tokenKey);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    return http.Response.fromStream(streamed);
  }
}
