import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collabsme/core/constants/app_constants.dart';
import 'package:collabsme/data/models/task_model.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/presentation/providers/company_provider.dart';
import 'package:collabsme/presentation/widgets/app_toast.dart';
import 'package:collabsme/data/repositories/task_repository.dart';
import 'package:intl/intl.dart';

class TaskEditScreen extends ConsumerStatefulWidget {
  final String projectId;
  final TaskModel task;

  const TaskEditScreen({
    super.key,
    required this.projectId,
    required this.task,
  });

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late String _priority;
  late String _status;
  UserModel? _selectedAssignee;
  DateTime? _dueDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.task.title;
    _descCtrl.text = widget.task.description;
    _priority = widget.task.priority;
    _status = widget.task.status;
    if (widget.task.dueDate != null) _dueDate = widget.task.dueDate;
  }

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
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      AppToast.show(context, message: "Le titre est requis", type: ToastType.error);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final repo = TaskRepository();
      await repo.updateTask(widget.projectId, widget.task.id, {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'status': _status,
        'assigned_to': _selectedAssignee?.id,
        'due_date': _dueDate?.toIso8601String().split('T')[0],
      });
      if (mounted) {
        AppToast.show(context, message: "Tâche modifiée", type: ToastType.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          "Modifier la tâche",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              const Text("TITRE *", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
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

              const Text("STATUT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.trello, size: 20),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'TODO', child: Text('À faire')),
                  DropdownMenuItem(value: 'IN_PROGRESS', child: Text('En cours')),
                  DropdownMenuItem(value: 'REVIEW', child: Text('En révision')),
                  DropdownMenuItem(value: 'DONE', child: Text('Terminé')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'TODO'),
              ),
              const SizedBox(height: 24),

              const Text("ASSIGNER À", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              membersAsync.when(
                loading: () => const SizedBox(height: 40),
                error: (_, _) => const SizedBox(height: 40),
                data: (members) {
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
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Non assigné")),
                      ...members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName))),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedAssignee = members.firstWhere((m) => m.id == v));
                      } else {
                        setState(() => _selectedAssignee = null);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

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
                      : const Text("Enregistrer les modifications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
