import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';
import '../../utils/safe_parser.dart';

class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await ApiClient.post('auth/login/', {
        'email': email,
        'password': password,
      }, authenticated: false);

      if (response.statusCode == 200) {
        final json = SafeParser.safeDecodeMap(response.body);
        if (json != null) {
          final tokens = json['tokens'] as Map<String, dynamic>?;
          if (tokens != null) {
            final access = SafeParser.parseString(tokens['access']);
            if (access.isNotEmpty) await ApiClient.saveToken(access);
            final refresh = SafeParser.parseString(tokens['refresh']);
            if (refresh.isNotEmpty) await ApiClient.saveRefreshToken(refresh);
          }
        }
        return await getMe();
      }

      if (response.statusCode == 429) {
        throw ApiException("Trop de tentatives de connexion. Veuillez patienter quelques minutes.");
      }

      final errorData = SafeParser.safeJsonDecode(response.body);
      String message = "Identifiants incorrects";
      Map<String, dynamic>? errors;

      if (errorData is Map) {
        if (errorData.containsKey('detail')) {
          message = SafeParser.parseString(errorData['detail']);
        } else if (errorData.containsKey('error')) {
          message = SafeParser.parseString(errorData['error']);
        }
        errors = Map<String, dynamic>.from(errorData);
      }
      throw ApiException(message, errors: errors);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur d'authentification : $e");
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await ApiClient.get('auth/me/');
      if (response.statusCode == 200) {
        final json = SafeParser.safeDecodeMap(response.body) ?? {};
        return UserModel.fromJson(json);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiException("Session expirée", statusCode: response.statusCode);
      }
      throw ApiException("Erreur serveur (${response.statusCode})", statusCode: response.statusCode);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

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
        final errorData = SafeParser.safeJsonDecode(response.body);
        String message = "Erreur d'inscription";
        Map<String, dynamic>? errors;

        if (errorData is Map) {
          if (errorData.containsKey('detail')) {
            message = SafeParser.parseString(errorData['detail']);
          } else {
            errors = Map<String, dynamic>.from(errorData);
            if (errors.containsKey('non_field_errors') && errors['non_field_errors'] is List) {
              message = (errors['non_field_errors'] as List).join(" ");
            } else if (errors.isNotEmpty) {
              final firstError = errors.entries.first;
              message = "${firstError.key}: ${firstError.value is List ? (firstError.value as List).join(" ") : firstError.value}";
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

  Future<void> resetPasswordConfirm({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final response = await ApiClient.post('auth/password-reset/confirm/', {
      'email': uid,
      'token': token,
      'new_password': newPassword,
    });
    if (response.statusCode != 200) {
      throw ApiException("Erreur lors de la réinitialisation du mot de passe (${response.statusCode})");
    }
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (bio != null) body['bio'] = bio;
      if (preferences != null) body['preferences'] = preferences;
      final response = await ApiClient.patch('auth/me/', body);

      if (response.statusCode == 200) {
        final json = SafeParser.safeDecodeMap(response.body) ?? {};
        return UserModel.fromJson(json);
      }
      throw ApiException("Erreur lors de la mise à jour du profil (${response.statusCode})");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

  Future<void> deleteAccount() async {
    final response = await ApiClient.delete('auth/me/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException("Erreur lors de la suppression du compte (${response.statusCode})");
    }
  }

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

  Future<void> logout() async {
    final refresh = await ApiClient.getRefreshToken();
    if (refresh != null) {
      try {
        await ApiClient.post('auth/logout/', {'refresh': refresh});
      } catch (_) {
        // ignore logout errors — best-effort
      }
    }
    await ApiClient.removeToken();
    await ApiClient.removeRefreshToken();
  }

  Future<void> requestPasswordReset(String email) async {
    final response = await ApiClient.post('auth/password-reset/', {
      'email': email,
    }, authenticated: false);

    if (response.statusCode != 200) {
      throw ApiException("Erreur lors de la demande de réinitialisation (${response.statusCode})");
    }
  }

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
      throw ApiException("Lien invalide ou expiré (${response.statusCode})");
    }
  }
}
