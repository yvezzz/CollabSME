import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:collabsme/core/constants/app_constants.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/presentation/providers/project_provider.dart';
import 'package:collabsme/presentation/providers/company_provider.dart';
import 'package:collabsme/presentation/widgets/app_text_field.dart';
import 'package:collabsme/presentation/widgets/app_toast.dart';

class AddProjectScreen extends ConsumerStatefulWidget {
  const AddProjectScreen({super.key});

  @override
  ConsumerState<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends ConsumerState<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _priority = 'MEDIUM';
  UserModel? _selectedLead;
  final Set<String> _selectedMemberIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(projectListProvider.notifier).addProject(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        budget: double.tryParse(_budgetCtrl.text),
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
        leadId: _selectedLead != null ? int.parse(_selectedLead!.id) : null,
        memberIds: _selectedMemberIds.map((e) => int.parse(e)).toList(),
      );
      if (!context.mounted) return;
      Navigator.pop(context, true);
      AppToast.show(context, message: "Projet créé avec succès !", type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
    } finally {
      if (context.mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(companyMembersProvider);
    final users = membersAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Nouveau Projet",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.briefcase, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Lancez une nouvelle collaboration",
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                          const Text("Remplissez les informations ci-dessous",
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _titleCtrl,
                    label: "Titre du projet",
                    icon: LucideIcons.briefcase,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Titre requis" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date de début",
                            prefixIcon: const Icon(LucideIcons.calendar, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          controller: TextEditingController(text: _formatDate(_startDate)),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Date de fin",
                            prefixIcon: const Icon(LucideIcons.flag, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          controller: TextEditingController(text: _formatDate(_endDate)),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          dropdownColor: AppColors.surface,
                          decoration: InputDecoration(
                            labelText: "Priorité",
                            prefixIcon: const Icon(LucideIcons.flag, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'LOW', child: Text("Basse", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'MEDIUM', child: Text("Moyenne", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'HIGH', child: Text("Haute", style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'CRITICAL', child: Text("Critique", style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _budgetCtrl,
                          label: "Budget (FCFA)",
                          icon: LucideIcons.dollarSign,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _descCtrl,
                    label: "Description",
                    icon: LucideIcons.fileText,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<UserModel>(
                    value: _selectedLead,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: "Chef de projet",
                      prefixIcon: const Icon(LucideIcons.userCheck, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: users.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.fullName, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedLead = v),
                  ),
                  const SizedBox(height: 24),
                  Text("Membres (optionnel)",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  if (users.isEmpty)
                    const Text("Aucun membre disponible", style: TextStyle(color: AppColors.textSecondary, fontSize: 12))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: users.map((u) => FilterChip(
                        label: Text(u.fullName, style: const TextStyle(fontSize: 12)),
                        selected: _selectedMemberIds.contains(u.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) _selectedMemberIds.add(u.id);
                            else _selectedMemberIds.remove(u.id);
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.primary,
                        backgroundColor: AppColors.card,
                        labelStyle: TextStyle(
                          color: _selectedMemberIds.contains(u.id) ? AppColors.primary : Colors.white,
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Annuler", style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Créer le projet"),
                      ),
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
}
