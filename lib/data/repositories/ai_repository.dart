import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

final aiRepositoryProvider = Provider((ref) => AIRepository());

class AIRepository {
  /// Génère une description et des sous-tâches à partir d'un titre
  Future<Map<String, dynamic>> generateTaskContent(String title, String projectId) async {
    final response = await ApiClient.post('ai/generate-task/', {
      'title': title,
      'project_id': projectId,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("L'assistant IA n'a pas pu générer le contenu");
    }
  }

  /// Résume l'activité et l'avancement d'un projet
  Future<String> summarizeProject(String projectId) async {
    final response = await ApiClient.post('ai/summarize-project/', {
      'project_id': projectId,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['summary'] ?? "Aucun résumé disponible.";
    } else {
      throw Exception("Impossible de générer le résumé du projet");
    }
  }

  /// Discussion libre avec l'IA
  Future<String> chat(String message) async {
    final response = await ApiClient.post('ai/chat/', {
      'message': message,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception("L'assistant IA est temporairement indisponible.");
    }
  }

  /// Récupère l'historique des messages
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final response = await ApiClient.get('ai/chat/history/');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Impossible de charger l'historique du chat.");
    }
  }

  Future<void> clearChatHistory() async {
    await ApiClient.delete('ai/clear/');
  }
}
