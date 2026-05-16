import 'dart:convert';
import '../models/project_member_model.dart';
import '../../core/network/api_client.dart';

class ProjectMemberRepository {
  /// Liste les membres d'un projet spécifique
  Future<List<ProjectMemberModel>> getProjectMembers(String projectId) async {
    final response = await ApiClient.get('projects/$projectId/members/');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ProjectMemberModel.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des membres");
    }
  }

  /// Ajoute un membre à un projet
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
      throw Exception("Impossible d'ajouter le membre");
    }
  }

  /// Retire un membre du projet
  Future<void> removeMember(String projectId, String memberId) async {
    final response = await ApiClient.delete(
      'projects/$projectId/members/$memberId/',
    );
    if (response.statusCode != 204) {
      throw Exception("Erreur lors du retrait du membre");
    }
  }

  /// Change le rôle d'un membre
  Future<void> updateMemberRole(
    String projectId,
    String memberId,
    String role,
  ) async {
    final response = await ApiClient.patch(
      'projects/$projectId/members/$memberId/',
      {'role': role},
    );
    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de rôle");
    }
  }
}
