import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_container.dart';
import '../../providers/task_provider.dart';
import '../../../data/models/task_model.dart';
import '../../screens/tasks/task_detail_screen.dart';
import 'package:intl/intl.dart';

/// Écran de gestion des tâches personnelles de l'utilisateur.
class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(userTasksProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final now = DateTime.now();
                final overdue = tasks
                    .where(
                      (t) =>
                          t.dueDate != null &&
                          t.dueDate!.isBefore(
                            DateTime(now.year, now.month, now.day),
                          ),
                    )
                    .toList();
                final today = tasks
                    .where(
                      (t) =>
                          t.dueDate != null &&
                          t.dueDate!.year == now.year &&
                          t.dueDate!.month == now.month &&
                          t.dueDate!.day == now.day,
                    )
                    .toList();
                final later = tasks
                    .where(
                      (t) =>
                          t.dueDate == null ||
                          t.dueDate!.isAfter(
                            DateTime(now.year, now.month, now.day),
                          ),
                    )
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(userTasksProvider),
                  child: ListView(
                    children: [
                      if (overdue.isNotEmpty)
                        _buildTaskCategory(
                          context,
                          "En retard",
                          AppColors.danger,
                          overdue,
                        ),
                      if (today.isNotEmpty)
                        _buildTaskCategory(
                          context,
                          "À faire aujourd'hui",
                          AppColors.primary,
                          today,
                        ),
                      _buildTaskCategory(
                        context,
                        "À faire plus tard",
                        AppColors.textSecondary,
                        later,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Erreur: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mes Tâches",
          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          "Gérez vos priorités et suivez votre avancement.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTaskCategory(BuildContext context, String title, Color color, List<TaskModel> tasks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${tasks.length}",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tasks.asMap().entries.map(
            (entry) => _buildTaskItem(context, entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, int index, TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: task.projectId != null
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TaskDetailScreen(
                    projectId: task.projectId!,
                    taskId: task.id,
                  ),
                ),
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    LucideIcons.circle,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (task.publicId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.publicId!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildPriorityBadge(task.priority),
                          const SizedBox(width: 12),
                          Text(
                            "Échéance : ${task.dueDate != null ? DateFormat('dd/MM/yyyy').format(task.dueDate!) : 'Non définie'}",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'URGENT':
        color = AppColors.danger;
        break;
      case 'HIGH':
        color = Colors.orange;
        break;
      case 'MEDIUM':
        color = Colors.blue;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Row(
      children: [
        Icon(LucideIcons.alertTriangle, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          priority,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
