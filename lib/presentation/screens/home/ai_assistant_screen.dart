import 'package:flutter/material.dart';
import 'package:collabsme/presentation/widgets/ai_chat_panel.dart';

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0c29),
      body: SafeArea(
        child: AIChatPanel(
          showHeader: true,
          showClearButton: true,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
