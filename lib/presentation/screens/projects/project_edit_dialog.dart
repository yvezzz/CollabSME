import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../presentation/providers/project_provider.dart';
import '../../../data/models/project_model.dart';

class ProjectEditDialog extends ConsumerStatefulWidget {
  final ProjectModel project;
  const ProjectEditDialog({super.key, required this.project});

  @override
  ConsumerState<ProjectEditDialog> createState() => _ProjectEditDialogState();
}

class _ProjectEditDialogState extends ConsumerState<ProjectEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _keyCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _startDateCtrl;
  late TextEditingController _endDateCtrl;
  late String _priority;
  late String _status;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.project.title);
    _descCtrl = TextEditingController(text: widget.project.description);
    _keyCtrl = TextEditingController(text: widget.project.key ?? '');
    _budgetCtrl = TextEditingController(
      text: widget.project.budget?.toStringAsFixed(2) ?? '',
    );
    _startDateCtrl = TextEditingController(
      text: widget.project.startDate != null
          ? '${widget.project.startDate!.year}-${widget.project.startDate!.month.toString().padLeft(2, '0')}-${widget.project.startDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
    _endDateCtrl = TextEditingController(
      text: widget.project.endDate != null
          ? '${widget.project.endDate!.year}-${widget.project.endDate!.month.toString().padLeft(2, '0')}-${widget.project.endDate!.day.toString().padLeft(2, '0')}'
          : '',
    );
    _priority = widget.project.priority;
    _status = widget.project.status;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _keyCtrl.dispose();
    _budgetCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Modifier le projet",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Titre",
                    prefixIcon: const Icon(LucideIcons.briefcase, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Titre requis" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _keyCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Clé",
                          prefixIcon: const Icon(LucideIcons.key, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _priority,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          labelText: "Priorité",
                          prefixIcon: const Icon(
                            LucideIcons.alertTriangle,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Description",
                    prefixIcon: const Icon(LucideIcons.fileText, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _budgetCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Budget (€)",
                          prefixIcon: const Icon(
                            LucideIcons.dollarSign,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          labelText: "Statut",
                          prefixIcon: const Icon(LucideIcons.radio, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: ['DRAFT', 'ACTIVE', 'COMPLETED', 'ARCHIVED']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Date début (YYYY-MM-DD)",
                          prefixIcon: const Icon(
                            LucideIcons.calendar,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Date fin (YYYY-MM-DD)",
                          prefixIcon: const Icon(
                            LucideIcons.calendarCheck,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Annuler",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Enregistrer"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(singleProjectProvider(widget.project.id).notifier)
          .updateProject(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            key: _keyCtrl.text.trim().isEmpty
                ? null
                : _keyCtrl.text.trim().toUpperCase(),
            priority: _priority,
            status: _status,
            budget: double.tryParse(_budgetCtrl.text),
            startDate: _startDateCtrl.text.trim().isEmpty
                ? null
                : _startDateCtrl.text.trim(),
            endDate: _endDateCtrl.text.trim().isEmpty
                ? null
                : _endDateCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur: $e",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
