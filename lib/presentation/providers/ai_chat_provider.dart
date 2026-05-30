import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ai_repository.dart';

class AIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatState {
  final List<AIChatMessage> messages;
  final bool isTyping;

  AIChatState({
    this.messages = const [],
    this.isTyping = false,
  });

  AIChatState copyWith({
    List<AIChatMessage>? messages,
    bool? isTyping,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  return AIChatNotifier(ref.watch(aiRepositoryProvider));
});

class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIRepository _repository;

  AIChatNotifier(this._repository) : super(AIChatState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      state = state.copyWith(isTyping: true);
      final history = await _repository.getChatHistory();
      
      if (history.isEmpty) {
        state = state.copyWith(
          messages: [
            AIChatMessage(
              text: "Bonjour ! Je suis votre assistant CollabSME AI. Comment puis-je vous aider aujourd'hui ?",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
          isTyping: false,
        );
        return;
      }

      final messages = history.map((m) => AIChatMessage(
        text: m['content'] ?? '',
        isUser: m['role'] == 'user',
        timestamp: m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now(),
      )).toList();

      state = state.copyWith(
        messages: messages,
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        messages: [
          AIChatMessage(
            text: "Bonjour ! Je suis votre assistant CollabSME AI. Comment puis-je vous aider aujourd'hui ?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = AIChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    try {
      String response;
      if (text.toLowerCase().contains("tâche") || text.toLowerCase().contains("task")) {
        final result = await _repository.generateTaskContent(text, "");
        response = result['description'] ?? "J'ai généré les détails de la tâche.";
      } else {
        response = await _repository.chat(text);
      }

      final aiMsg = AIChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
      );
    } catch (e) {
      final errorMsg = AIChatMessage(
        text: "Désolé, j'ai rencontré une erreur technique. Veuillez réessayer.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isTyping: false,
      );
    }
  }

  Future<void> clearHistory() async {
    try {
      await _repository.clearChatHistory();
    } catch (_) {}
    state = AIChatState(messages: [
      AIChatMessage(
        text: "Historique effacé. Comment puis-je vous aider ?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ]);
  }
}
