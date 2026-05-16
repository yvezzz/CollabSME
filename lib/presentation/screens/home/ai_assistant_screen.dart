import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collabsme/presentation/providers/ai_chat_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_container.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  static const _suggestions = [
    "Résumer mon projet",
    "Proposer des tâches pour la semaine",
    "Analyser les délais et les risques",
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isClearing = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(AIChatNotifier chatNotifier, {String? text}) {
    final msg = text ?? _controller.text.trim();
    if (msg.isEmpty) return;
    _controller.clear();
    chatNotifier.sendMessage(msg);
  }

  Future<void> _handleClearHistory(AIChatNotifier chatNotifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Effacer l'historique",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Toute la conversation sera supprimée. Confirmez-vous ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text("Effacer"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isClearing = true);
    await chatNotifier.clearHistory();
    if (mounted) setState(() => _isClearing = false);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final chatNotifier = ref.read(aiChatProvider.notifier);

    // Scroll to bottom when new messages arrive
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Assistant CollabSME AI",
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            softWrap: true,
                          ),
                          Text(
                            "Toujours là pour vous aider",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                    _isClearing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white24,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              color: Colors.white24,
                              size: 20,
                            ),
                            onPressed: () => _handleClearHistory(chatNotifier),
                          ),
                  ],
                ),
              ),

              // Suggestions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        onPressed: () => _handleSend(chatNotifier, text: s),
                      ),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount:
                      chatState.messages.length + (chatState.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatState.messages.length) {
                      return _buildTypingIndicator().animate().fadeIn();
                    }
                    return _buildMessageBubble(chatState.messages[index]);
                  },
                ),
              ),

              // Input Area
              Padding(
                padding: const EdgeInsets.all(24),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText:
                                "Expliquez-moi votre projet ou posez une question...",
                            hintStyle: const TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _handleSend(chatNotifier);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _handleSend(chatNotifier),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIChatMessage msg) {
    return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24).copyWith(
                bottomRight: msg.isUser
                    ? const Radius.circular(0)
                    : const Radius.circular(24),
                bottomLeft: msg.isUser
                    ? const Radius.circular(24)
                    : const Radius.circular(0),
              ),
              border: Border.all(
                color: msg.isUser ? Colors.white24 : Colors.white12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: msg.isUser ? 0.1 : -0.1, end: 0);
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(
            24,
          ).copyWith(bottomLeft: Radius.zero),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "CollabSME AI est en train d'écrire...",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
