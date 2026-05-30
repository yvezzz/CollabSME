import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';
import '../../utils/safe_parser.dart';

class InvitationRepository {
  Future<List<Map<String, dynamic>>> getInvitations() async {
    try {
      final response = await ApiClient.get('invitations/');
      if (response.statusCode == 200) {
        final decoded = SafeParser.safeJsonDecode(response.body);
        final List data = decoded is Map ? (decoded['results'] ?? []) : (decoded is List ? decoded : []);
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> cancelInvitation(String id) async {
    final response = await ApiClient.delete('invitations/$id/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException("Erreur lors de l'annulation de l'invitation (${response.statusCode})");
    }
  }

  Future<void> sendInvitation(String email, {String role = 'MEMBER'}) async {
    try {
      final response = await ApiClient.post('invitations/', {
        'email': email,
        'role': role,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = SafeParser.safeJsonDecode(response.body);
        String message = "Erreur lors de l'envoi de l'invitation";
        Map<String, dynamic>? errors;

        if (errorData is Map) {
          message = SafeParser.parseString(errorData['error']);
          if (message.isEmpty) message = SafeParser.parseString(errorData['detail']);
          if (message.isEmpty) {
            final firstError = (errorData.values).firstWhere(
              (v) => v is List && v.isNotEmpty,
              orElse: () => null,
            );
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError[0].toString();
            }
          }
          if (message.isEmpty) message = "Erreur lors de l'envoi de l'invitation";
          errors = errorData is Map<String, dynamic> ? errorData : null;
        }
        throw ApiException(message, errors: errors);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final response = await ApiClient.get('invitations/validate/$token/', authenticated: false);
      if (response.statusCode != 200) {
        throw ApiException("Lien d'invitation invalide ou expiré");
      }
      return SafeParser.parseJsonMap(response.body);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur de validation : $e");
    }
  }

  Future<void> declineInvitation(String token) async {
    try {
      final response = await ApiClient.post('invitations/decline/$token/', {}, authenticated: false);
      if (response.statusCode != 200) {
        throw ApiException("Erreur lors du refus de l'invitation (${response.statusCode})");
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

  Future<void> acceptInvitation({
    required String token,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post('invitations/accept/$token/', {
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      }, authenticated: false);

      if (response.statusCode == 201) {
        final data = SafeParser.safeDecodeMap(response.body);
        if (data != null && data['tokens'] is Map) {
          await ApiClient.saveToken(SafeParser.parseString(data['tokens']['access']));
          final refresh = SafeParser.parseString(data['tokens']['refresh']);
          if (refresh.isNotEmpty) await ApiClient.saveRefreshToken(refresh);
        }
      } else {
        final errorData = SafeParser.safeJsonDecode(response.body);
        String message = "Erreur lors de l'acceptation";
        Map<String, dynamic>? errors;

        if (errorData is Map) {
          message = SafeParser.parseString(errorData['error']);
          if (message.isEmpty) message = SafeParser.parseString(errorData['detail']);
          if (message.isEmpty) {
            final firstError = (errorData.values).firstWhere(
              (v) => v is List && v.isNotEmpty,
              orElse: () => null,
            );
            if (firstError is List && firstError.isNotEmpty) {
              message = firstError[0].toString();
            }
          }
          if (message.isEmpty) message = "Erreur lors de l'envoi de l'invitation";
          errors = errorData is Map<String, dynamic> ? errorData : null;
        }
        throw ApiException(message, errors: errors);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }
}
