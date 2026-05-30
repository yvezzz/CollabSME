import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';
import '../models/project_member_model.dart';

class ProjectMemberRepository {
  Future<List<ProjectMemberModel>> getProjectMembers(String projectId) async {
    final response = await ApiClient.get('projects/$projectId/members/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeDecodeList(response.body);
      if (decoded == null) return [];
      return decoded.whereType<Map<String, dynamic>>().map((json) => ProjectMemberModel.fromJson(json)).toList();
    }
    throw Exception("Erreur lors de la récupération des membres (${response.statusCode})");
  }

  Future<void> addMember({
    required String projectId,
    required String userId,
    String role = 'MEMBER',
  }) async {
    final response = await ApiClient.post('projects/$projectId/members/', {
      'user': userId,
      'role': role,
    });
    if (response.statusCode != 201) {
      throw Exception("Impossible d'ajouter le membre (${response.statusCode})");
    }
  }

  Future<void> removeMember(String projectId, String memberId) async {
    final response = await ApiClient.delete('projects/$projectId/members/$memberId/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception("Erreur lors du retrait du membre (${response.statusCode})");
    }
  }

  Future<void> updateMemberRole(String projectId, String memberId, String role) async {
    final response = await ApiClient.patch(
      'projects/$projectId/members/$memberId/',
      {'role': role},
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de rôle (${response.statusCode})");
    }
  }
}
