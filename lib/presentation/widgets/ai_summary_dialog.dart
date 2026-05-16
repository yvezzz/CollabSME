import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/repositories/ai_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/glass_container.dart';

class AISummaryDialog extends StatefulWidget {
  final String projectId;
  const AISummaryDialog({super.key, required this.projectId});

  @override
  State<AISummaryDialog> createState() => _AISummaryDialogState();
}

class _AISummaryDialogState extends State<AISummaryDialog> {
  final _aiRepo = AIRepository();
  String? _summary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final summary = await _aiRepo.summarizeProject(widget.projectId);
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Résumé Smart IA",
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                _buildLoadingState()
              else if (_error != null)
                _buildErrorState()
              else
                _buildSummaryContent(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text("Fermer"),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text("Analyse du projet en cours...", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Text("Erreur : $_error", style: const TextStyle(color: AppColors.danger));
  }

  Widget _buildSummaryContent() {
    return Flexible(
      child: SingleChildScrollView(
        child: Text(
          _summary!,
          style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 14),
        ),
      ),
    );
  }
}
