import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/exceptions/api_exception.dart';

class InvitationRepository {
  /// Récupère les invitations en attente de l'entreprise (GET /api/invitations/)
  Future<List<Map<String, dynamic>>> getInvitations() async {
    try {
      final response = await ApiClient.get('invitations/');
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is Map ? (decoded['results'] ?? []) : decoded;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Supprime/annule une invitation (DELETE /api/invitations/{id}/)
  Future<void> cancelInvitation(String id) async {
    final response = await ApiClient.delete('invitations/$id/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException("Erreur lors de l'annulation de l'invitation");
    }
  }

  /// Envoie une invitation (POST /api/invitations/)
  Future<void> sendInvitation(String email, {String role = 'MEMBER'}) async {
    try {
      final response = await ApiClient.post('invitations/', {
        'email': email,
        'role': role,
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        String message = "Erreur lors de l'envoi de l'invitation";
        Map<String, dynamic>? errors;
        
        if (errorData is Map) {
          message = errorData['error'] ?? errorData['detail'] ?? '';
          if (message.isEmpty) {
            final firstError = errorData.values.firstWhere(
              (v) => v is List && v.isNotEmpty,
              orElse: () => [],
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

  /// Valide un token d'invitation (GET /api/invitations/validate/{token}/)
  Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      final response = await ApiClient.get('invitations/validate/$token/', authenticated: false);
      if (response.statusCode != 200) {
        throw ApiException("Lien d'invitation invalide ou expiré");
      }
      return jsonDecode(response.body);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur de validation : $e");
    }
  }

  /// Décline l'invitation (POST /api/invitations/decline/{token}/)
  Future<void> declineInvitation(String token) async {
    try {
      final response = await ApiClient.post('invitations/decline/$token/', {}, authenticated: false);
      if (response.statusCode != 200) {
        throw ApiException("Erreur lors du refus de l'invitation");
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Erreur réseau : $e");
    }
  }

  /// Accepte l'invitation et crée le compte (POST /api/invitations/accept/{token}/)
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
        final data = jsonDecode(response.body);
        
        // Sauvegarde des tokens pour connexion auto
        if (data['tokens'] != null) {
          await ApiClient.saveToken(data['tokens']['access']);
          await ApiClient.saveRefreshToken(data['tokens']['refresh']);
        }
      } else {
        final errorData = jsonDecode(response.body);
        String message = "Erreur lors de l'acceptation";
        Map<String, dynamic>? errors;

        if (errorData is Map) {
          message = errorData['error'] ?? errorData['detail'] ?? '';
          if (message.isEmpty) {
            final firstError = errorData.values.firstWhere(
              (v) => v is List && v.isNotEmpty,
              orElse: () => [],
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
