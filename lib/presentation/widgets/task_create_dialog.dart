import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_model.dart';
import '../providers/company_provider.dart';

class TaskCreateDialog extends ConsumerStatefulWidget {
  final String columnStatus;

  const TaskCreateDialog({super.key, this.columnStatus = 'TODO'});

  @override
  ConsumerState<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends ConsumerState<TaskCreateDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  UserModel? _selectedAssignee;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(companyMembersProvider);

    return AlertDialog(
      backgroundColor: AppColors.card,
      title: const Text("Nouvelle tâche"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Titre *",
                prefixIcon: Icon(LucideIcons.text, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: "Description",
                prefixIcon: Icon(LucideIcons.alignLeft, size: 18),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: "Priorité",
                prefixIcon: Icon(LucideIcons.flag, size: 18),
              ),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                DropdownMenuItem(value: 'CRITICAL', child: Text('Critique')),
              ],
              onChanged: (v) => setState(() => _priority = v ?? 'MEDIUM'),
            ),
            const SizedBox(height: 12),
            membersAsync.when(
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox(height: 40),
              data: (members) => DropdownButtonFormField<String>(
                value: _selectedAssignee?.id,
                decoration: const InputDecoration(
                  labelText: "Assigné à",
                  prefixIcon: Icon(LucideIcons.user, size: 18),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Non assigné")),
                  ...members.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.fullName),
                  )),
                ],
                onChanged: (v) => setState(() {
                  _selectedAssignee = v != null ? members.firstWhere((m) => m.id == v) : null;
                }),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Date d'échéance",
                  prefixIcon: Icon(LucideIcons.calendar, size: 18),
                ),
                child: Text(
                  _dueDate != null
                      ? "${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}"
                      : "Sélectionner une date",
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        FilledButton(
          onPressed: () {
            if (_titleCtrl.text.trim().isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleCtrl.text.trim(),
                'description': _descCtrl.text.trim(),
                'priority': _priority,
                'assigned_to': _selectedAssignee?.id,
                'due_date': _dueDate?.toIso8601String(),
              });
            }
          },
          child: const Text("Créer"),
        ),
      ],
    );
  }
}
