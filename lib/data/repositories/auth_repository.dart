import 'dart:convert';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';

import '../../core/exceptions/api_exception.dart';

/// Gère les opérations liées à l'authentification via l'API CollabSME.
class AuthRepository {
  /// Tentative de connexion via l'API (JWT)
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await ApiClient.post('auth/login/', {
        'email': email,
        'password': password,
      }, authenticated: false);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final tokens = json['tokens'] as Map<String, dynamic>?;

        if (tokens != null) {
          final access = tokens['access'] as String?;
          if (access != null) await ApiClient.saveToken(access);
          final refresh = tokens['refresh'] as String?;
          if (refresh != null) await ApiClient.saveRefreshToken(refresh);
        }

        return await getMe();
      } else if (response.statusCode == 429) {
        throw ApiException(
          "Trop de tentatives de connexion. Veuillez patienter quelques minutes.",
        );
      } else {
        final errorData = jsonDecode(response.body);
        String message = "Identifiants incorrects";
        Map<String, dynamic>? errors;

        if (errorData is Map) {
          if (errorData.containsKey('detail')) {
            message = errorData['detail'];
          } else if (errorData.containsKey('error')) {
            message = errorData['error'];
          }
          errors = Map<String, dynamic>.from(errorData);
        }
        throw ApiException(message, errors: errors);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur d'authentification : $e");
    }
  }

  /// Récupère le profil de l'utilisateur connecté (GET /api/auth/me/)
  Future<UserModel> getMe() async {
    try {
      final response = await ApiClient.get('auth/me/');
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiException("Session expirée", statusCode: response.statusCode);
      } else {
        throw ApiException(
          "Erreur serveur (${response.statusCode})",
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

  /// Inscription d'une nouvelle entreprise + Admin
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String companyName,
    String? phoneNumber,
  }) async {
    try {
      final response = await ApiClient.post('auth/register/', {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'company_name': companyName,
        'phone_number': phoneNumber,
      }, authenticated: false);

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        String message = "Erreur d'inscription";
        Map<String, dynamic>? errors;

        if (errorData is Map) {
          if (errorData.containsKey('detail')) {
            message = errorData['detail'];
          } else {
            // API validation errors are usually a Map<String, List<String>>
            errors = Map<String, dynamic>.from(errorData);

            // Try to find a human readable message
            if (errors.containsKey('non_field_errors') && errors['non_field_errors'] is List) {
              message = (errors['non_field_errors'] as List).join(" ");
            } else if (errors.isNotEmpty) {
              final firstError = errors.entries.first;
              final field = firstError.key;
              final errorVal = firstError.value;
              message =
                  "$field: ${errorVal is List ? errorVal.join(" ") : errorVal}";
            }
          }
        }
        throw ApiException(message, errors: errors);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

  /// Mettre à jour le profil
  Future<void> resetPasswordConfirm({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    await ApiClient.post('auth/password-reset/confirm/', {
      'email': uid,
      'token': token,
      'new_password': newPassword,
    });
  }

  /// Mettre à jour le profil
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (bio != null) body['bio'] = bio;
    if (preferences != null) body['preferences'] = preferences;
    final response = await ApiClient.patch('auth/me/', body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw ApiException("Erreur lors de la mise à jour du profil");
  }

  /// Supprimer le compte utilisateur
  Future<void> deleteAccount() async {
    final response = await ApiClient.delete('auth/me/');
    if (response.statusCode != 204) {
      throw ApiException("Erreur lors de la suppression du compte");
    }
  }

  /// Vérifie le mot de passe actuel sans sauvegarder les tokens
  Future<bool> verifyPassword(String email, String password) async {
    try {
      final response = await ApiClient.post('auth/login/', {
        'email': email,
        'password': password,
      }, authenticated: false);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Déconnexion : Supprime les tokens locaux et révoque le refresh token si possible
  Future<void> logout() async {
    final refresh = await ApiClient.getRefreshToken();
    if (refresh != null) {
      try {
        await ApiClient.post('auth/logout/', {'refresh': refresh});
      } catch (_) {
        // On ignore l'erreur si le token est déjà expiré ou invalide
      }
    }
    await ApiClient.removeToken();
    await ApiClient.removeRefreshToken();
  }

  /// Demander une réinitialisation de mot de passe
  Future<void> requestPasswordReset(String email) async {
    final response = await ApiClient.post('auth/password-reset/', {
      'email': email,
    }, authenticated: false);

    if (response.statusCode != 200) {
      throw ApiException("Erreur lors de la demande de réinitialisation");
    }
  }

  /// Confirmer la réinitialisation de mot de passe
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await ApiClient.post('auth/password-reset/confirm/', {
      'email': email,
      'token': token,
      'new_password': newPassword,
    }, authenticated: false);

    if (response.statusCode != 200) {
      throw ApiException("Lien invalide ou expiré");
    }
  }
}
