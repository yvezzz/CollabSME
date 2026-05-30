import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../presentation/providers/project_provider.dart';
import '../../../data/models/project_model.dart';

class ProjectEditScreen extends ConsumerStatefulWidget {
  final ProjectModel project;
  const ProjectEditScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends ConsumerState<ProjectEditScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          "Modifier le projet",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Enregistrer"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField("Titre", LucideIcons.briefcase, _titleCtrl, validator: (v) => (v == null || v.isEmpty) ? "Titre requis" : null),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField("Clé", LucideIcons.key, _keyCtrl)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPriorityDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField("Description", LucideIcons.fileText, _descCtrl, maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField("Budget (FCFA)", LucideIcons.coins, _budgetCtrl, isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusDropdown()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField("Date début (YYYY-MM-DD)", LucideIcons.calendar, _startDateCtrl)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField("Date fin (YYYY-MM-DD)", LucideIcons.calendarCheck, _endDateCtrl)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctrl, {int maxLines = 1, bool isNumber = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: validator,
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: _priority,
      dropdownColor: AppColors.card,
      decoration: InputDecoration(
        labelText: "Priorité",
        prefixIcon: const Icon(LucideIcons.alertTriangle, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
      items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
          .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 12))))
          .toList(),
      onChanged: (v) => setState(() => _priority = v!),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      dropdownColor: AppColors.card,
      decoration: InputDecoration(
        labelText: "Statut",
        prefixIcon: const Icon(LucideIcons.radio, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      style: const TextStyle(color: Colors.white),
      items: ['DRAFT', 'ACTIVE', 'COMPLETED', 'ARCHIVED']
          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12))))
          .toList(),
      onChanged: (v) => setState(() => _status = v!),
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
            key: _keyCtrl.text.trim().isEmpty ? null : _keyCtrl.text.trim().toUpperCase(),
            priority: _priority,
            status: _status,
            budget: double.tryParse(_budgetCtrl.text),
            startDate: _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
            endDate: _endDateCtrl.text.trim().isEmpty ? null : _endDateCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e", style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
