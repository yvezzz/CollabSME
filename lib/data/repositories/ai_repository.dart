import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../utils/safe_parser.dart';

final aiRepositoryProvider = Provider((ref) => AIRepository());

class AIRepository {
  Future<Map<String, dynamic>> generateTaskContent(String title, String projectId) async {
    final response = await ApiClient.post('ai/generate-task/', {
      'title': title,
      'project_id': projectId,
    });

    if (response.statusCode == 200) {
      final json = SafeParser.safeDecodeMap(response.body) ?? {};
      return json;
    }
    throw Exception("L'assistant IA n'a pas pu générer le contenu (${response.statusCode})");
  }

  Future<String> summarizeProject(String projectId) async {
    final response = await ApiClient.post('ai/summarize-project/', {
      'project_id': projectId,
    });

    if (response.statusCode == 200) {
      final data = SafeParser.safeDecodeMap(response.body);
      return SafeParser.parseString(data?['summary'], defaultValue: "Aucun résumé disponible.");
    }
    throw Exception("Impossible de générer le résumé du projet (${response.statusCode})");
  }

  Future<String> chat(String message) async {
    final response = await ApiClient.post('ai/chat/', {
      'message': message,
    });

    if (response.statusCode == 200) {
      final data = SafeParser.safeDecodeMap(response.body);
      return SafeParser.parseString(data?['response'], defaultValue: "Désolé, je n'ai pas pu traiter votre demande.");
    }
    throw Exception("L'assistant IA est temporairement indisponible (${response.statusCode})");
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final response = await ApiClient.get('ai/chat/');
    if (response.statusCode == 200) {
      final decoded = SafeParser.safeDecodeList(response.body);
      if (decoded == null) return [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    throw Exception("Impossible de charger l'historique du chat (${response.statusCode})");
  }

  Future<void> clearChatHistory() async {
    final response = await ApiClient.delete('ai/chat/');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Impossible d'effacer l'historique (${response.statusCode})");
    }
  }
}
