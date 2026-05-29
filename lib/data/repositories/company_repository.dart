import 'dart:convert';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class CompanyRepository {
  /// Récupère les infos de l'entreprise actuelle
  Future<Map<String, dynamic>> getCompany() async {
    final response = await ApiClient.get('companies/detail/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Erreur lors du chargement de l'entreprise");
  }

  /// Met à jour les infos de l'entreprise
  Future<void> updateCompany(Map<String, dynamic> data) async {
    final response = await ApiClient.patch('companies/detail/', data);
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la mise à jour");
    }
  }

  /// Récupère la liste des membres de l'entreprise actuelle
  Future<List<UserModel>> getMembers() async {
    final response = await ApiClient.get('companies/members/');
    if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List data = decoded is Map ? (decoded['results'] is List ? decoded['results'] : []) : (decoded is List ? decoded : []);
      return data.map((json) => UserModel.fromJson(json)).toList();
    }
    return [];
  }

  /// Retire un membre de l'entreprise (admin seulement)
  Future<void> removeMember(String userId) async {
    final response = await ApiClient.delete('companies/members/$userId/remove/');
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Erreur lors du retrait du membre');
    }
  }

  /// Change le rôle d'un membre (admin seulement)
  Future<void> changeMemberRole(String userId, String newRole) async {
    final response = await ApiClient.patch('companies/members/$userId/role/', {
      'role': newRole,
    });
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Erreur lors du changement de rôle');
    }
  }
}
