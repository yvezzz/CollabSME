import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collabsme/core/constants/app_constants.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/presentation/providers/auth_provider.dart';
import 'package:collabsme/presentation/providers/company_provider.dart';
import 'package:collabsme/presentation/widgets/app_toast.dart';
import 'package:intl/intl.dart';

class TaskCreateScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String columnStatus;

  const TaskCreateScreen({
    super.key,
    required this.projectId,
    this.columnStatus = 'TODO',
  });

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  UserModel? _selectedAssignee;
  DateTime? _dueDate;
  bool _isSubmitting = false; // ignore: prefer_final_fields

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      AppToast.show(context, message: "Le titre est requis", type: ToastType.error);
      return;
    }
    Navigator.of(context).pop({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _priority,
      'assigned_to': _selectedAssignee?.id,
      'due_date': _dueDate?.toIso8601String().split('T')[0],
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(companyMembersProvider);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.15 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          "Nouvelle tâche",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Créer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              const Text("Titre *", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Que faut-il faire ?",
                  prefixIcon: const Icon(LucideIcons.text, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Description
              const Text("DESCRIPTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Décrivez la tâche en détail...",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(LucideIcons.alignLeft, size: 20),
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Priorité
              const Text("PRIORITÉ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.flag, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critique')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
              ),
              const SizedBox(height: 24),

              // Assigné
              const Text("ASSIGNER À", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              membersAsync.when(
                loading: () => const SizedBox(height: 40),
                error: (_, _) => const SizedBox(height: 40),
                data: (members) {
                  final filtered = members.where((m) => m.role != 'ADMIN' || m.id == ref.read(authStateProvider).value?.id).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedAssignee?.id,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.user, size: 20),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white),
                    hint: const Text("Non assigné", style: TextStyle(color: AppColors.textSecondary)),
                    items: filtered.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text(m.fullName),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedAssignee = filtered.firstWhere((m) => m.id == v));
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // Date d'échéance
              const Text("DATE D'ÉCHÉANCE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_dueDate!)
                            : "Choisir une date",
                        style: TextStyle(
                          fontSize: 15,
                          color: _dueDate != null ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bouton Créer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Créer la tâche", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
