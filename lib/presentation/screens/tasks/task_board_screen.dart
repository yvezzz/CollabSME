import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/task_model.dart';
import '../../../widgets/glass_container.dart';
import '../../../presentation/widgets/task_create_dialog.dart';
import 'task_detail_screen.dart';
import '../../../presentation/widgets/app_toast.dart';

Future<void> _promptNewTask(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  String columnStatus,
) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => TaskCreateDialog(columnStatus: columnStatus),
  );
  if (result != null && context.mounted) {
    try {
      await ref
          .read(taskListProvider(projectId).notifier)
          .createTaskInColumn(
            title: result['title'],
            description: result['description'] ?? '',
            status: columnStatus,
            assignedTo: result['assigned_to'],
            priority: result['priority'] ?? 'MEDIUM',
            dueDate: result['due_date'],
          );
      if (context.mounted) {
        AppToast.show(context, message: 'Tâche créée', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.show(context, message: 'Erreur : $e', type: ToastType.error);
      }
    }
  }
}

class TaskBoardScreen extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const TaskBoardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskListProvider(projectId));
    final user = ref.watch(authStateProvider).value;
    final canCreate =
        user != null && (user.isCompanyAdmin || user.role != 'MEMBER');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kanban : $projectName",
          style: GoogleFonts.outfit(fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: taskState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Erreur: $err", style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(taskListProvider(projectId)),
                icon: const Icon(LucideIcons.refreshCcw, size: 16),
                label: const Text("Réessayer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        data: (tasks) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final h =
                  constraints.hasBoundedHeight && constraints.maxHeight > 120
                  ? constraints.maxHeight - 24
                  : 520.0;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    height: h,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildColumn(
                          context,
                          ref,
                          "À faire",
                          "TODO",
                          tasks.where((t) => t.status == 'TODO').toList(),
                          canCreate,
                        ),
                        _buildColumn(
                          context,
                          ref,
                          "En cours",
                          "IN_PROGRESS",
                          tasks
                              .where((t) => t.status == 'IN_PROGRESS')
                              .toList(),
                          canCreate,
                        ),
                        _buildColumn(
                          context,
                          ref,
                          "Révision",
                          "REVIEW",
                          tasks.where((t) => t.status == 'REVIEW').toList(),
                          canCreate,
                        ),
                        _buildColumn(
                          context,
                          ref,
                          "Terminé",
                          "DONE",
                          tasks.where((t) => t.status == 'DONE').toList(),
                          canCreate,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    WidgetRef ref,
    String title,
    String status,
    List<TaskModel> tasks,
    bool canCreate,
  ) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$title (${tasks.length})",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (canCreate)
                IconButton(
                  icon: const Icon(
                    LucideIcons.plus,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Nouvelle tâche',
                  onPressed: () =>
                      _promptNewTask(context, ref, projectId, status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                ref
                    .read(taskListProvider(projectId).notifier)
                    .moveTask(details.data, status);
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(context, ref, task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, TaskModel task) {
    return Draggable<String>(
      data: task.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 280, child: _taskCardContent(task)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _taskCardContent(task)),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          final droppedId = details.data;
          if (droppedId != task.id) {
            ref
                .read(taskListProvider(projectId).notifier)
                .moveTask(droppedId, task.status);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TaskDetailScreen(projectId: projectId, taskId: task.id),
                ),
              );
            },
            child: _taskCardContent(task),
          );
        },
      ),
    );
  }

  Widget _taskCardContent(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriorityIndicator(task.priority),
                  if (task.publicId != null)
                    Text(
                      task.publicId!,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.checkSquare,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${task.checklistItems.where((s) => s.isCompleted).length}/${task.checklistItems.length}",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    child: const Icon(
                      LucideIcons.user,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildPriorityIndicator(String priority) {
    Color color;
    switch (priority) {
      case 'URGENT':
      case 'HIGH':
        color = AppColors.danger;
        break;
      case 'MEDIUM':
        color = Colors.orange;
        break;
      case 'LOW':
        color = Colors.teal;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      width: 30,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
