import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';
import '../models/user_model.dart';

class CompanyRepository {
  Future<Map<String, dynamic>> getCompany() async {
    final response = await ApiClient.get('companies/detail/');
    if (response.statusCode == 200) {
      return SafeParser.parseJsonMap(response.body);
    }
    throw Exception("Erreur lors du chargement de l'entreprise (${response.statusCode})");
  }

  Future<void> updateCompany(Map<String, dynamic> data) async {
    final response = await ApiClient.patch('companies/detail/', data);
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la mise à jour (${response.statusCode})");
    }
  }

  Future<List<UserModel>> getMembers() async {
    final response = await ApiClient.get('companies/members/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeJsonDecode(response.body);
      final List data = decoded is Map ? (decoded['results'] is List ? decoded['results'] : []) : (decoded is List ? decoded : []);
      return data.map((json) => json is Map<String, dynamic> ? UserModel.fromJson(json) : UserModel.fromJson({})).toList();
    }
    return [];
  }

  Future<void> removeMember(String userId) async {
    final response = await ApiClient.delete('companies/members/$userId/remove/');
    if (response.statusCode != 200) {
      final errorData = SafeParser.safeDecodeMap(response.body);
      throw Exception(errorData?['error'] ?? "Erreur lors du retrait du membre (${response.statusCode})");
    }
  }

  Future<void> changeMemberRole(String userId, String newRole) async {
    final response = await ApiClient.patch('companies/members/$userId/role/', {
      'role': newRole,
    });
    if (response.statusCode != 200) {
      final errorData = SafeParser.safeDecodeMap(response.body);
      throw Exception(errorData?['error'] ?? "Erreur lors du changement de rôle (${response.statusCode})");
    }
  }
}
