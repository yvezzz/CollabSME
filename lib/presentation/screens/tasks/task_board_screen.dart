import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_helper.dart';
import '../../../data/models/task_model.dart';
import '../../../widgets/glass_container.dart';

Future<void> _promptNewTask(
  BuildContext context,
  WidgetRef ref,
  String projectId,
  String columnStatus,
) async {
  final result = await Navigator.pushNamed(
    context,
    '${Routes.taskCreate}/$projectId',
    arguments: columnStatus,
  );
  if (result != null && context.mounted) {
    ref.invalidate(taskListProvider(projectId));
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
          "Tâches : $projectName",
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
        data: (tasks) => _TaskBoardContent(
          projectId: projectId,
          tasks: tasks,
          canCreate: canCreate,
        ),
      ),
    );
  }
}

class _TaskBoardContent extends ConsumerStatefulWidget {
  final String projectId;
  final List<TaskModel> tasks;
  final bool canCreate;

  const _TaskBoardContent({
    required this.projectId,
    required this.tasks,
    required this.canCreate,
  });

  @override
  ConsumerState<_TaskBoardContent> createState() => _TaskBoardContentState();
}

class _TaskBoardContentState extends ConsumerState<_TaskBoardContent> {
  bool _isTableView = true;
  String _filterQuery = '';

  List<TaskModel> get _filteredTasks {
    if (_filterQuery.isEmpty) return widget.tasks;
    final q = _filterQuery.toLowerCase();
    return widget.tasks.where((t) =>
      t.title.toLowerCase().contains(q) ||
      t.priority.toLowerCase().contains(q) ||
      t.status.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: _isTableView
              ? _buildTableView(context)
              : _buildKanbanView(context),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _filterQuery = v),
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Filtrer les tâches...",
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _viewToggle(LucideIcons.list, "Table", true),
          const SizedBox(width: 4),
          _viewToggle(LucideIcons.columns, "Kanban", false),
          if (widget.canCreate) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _promptNewTask(context, ref, widget.projectId, 'TODO'),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text("Tâche", style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _viewToggle(IconData icon, String label, bool isTable) {
    final active = _isTableView == isTable;
    return InkWell(
      onTap: () => setState(() => _isTableView = isTable),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppColors.primary : AppColors.textSecondary,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView(BuildContext context) {
    final tasks = _filteredTasks;
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.inbox, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text("Aucune tâche", style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GlassContainer(
        borderRadius: 12,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildTableHeader(),
            ...tasks.map((t) => _buildTableRow(context, t)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text("Tâche", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          const Expanded(flex: 1, child: Text("Priorité", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          const Expanded(flex: 1, child: Text("Statut", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          const Expanded(flex: 1, child: Text("Assigné", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, TaskModel task) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '${Routes.taskDetail}/${widget.projectId}/${task.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(task.title, style: const TextStyle(fontSize: 13, color: Colors.white))),
            Expanded(flex: 1, child: _priorityLabel(task.priority)),
            Expanded(flex: 1, child: _statusLabel(task.status)),
            Expanded(
              flex: 1,
              child: Text(
                task.assignedToName ?? "-",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.chevronRight, size: 16),
              color: AppColors.textSecondary,
              onPressed: () => Navigator.pushNamed(context, '${Routes.taskDetail}/${widget.projectId}/${task.id}'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanView(BuildContext context) {
    final tasks = _filteredTasks;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.hasBoundedHeight && constraints.maxHeight > 120
            ? constraints.maxHeight - 24
            : 520.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildKanbanColumn(context, "À faire", "TODO", tasks.where((t) => t.status == 'TODO').toList()),
                  _buildKanbanColumn(context, "En cours", "IN_PROGRESS", tasks.where((t) => t.status == 'IN_PROGRESS').toList()),
                  _buildKanbanColumn(context, "Révision", "REVIEW", tasks.where((t) => t.status == 'REVIEW').toList()),
                  _buildKanbanColumn(context, "Terminé", "DONE", tasks.where((t) => t.status == 'DONE').toList()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String title, String status, List<TaskModel> tasks) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$title (${tasks.length})",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (widget.canCreate)
                IconButton(
                  icon: const Icon(LucideIcons.plus, size: 16, color: AppColors.textSecondary),
                  tooltip: 'Nouvelle tâche',
                  onPressed: () => _promptNewTask(context, ref, widget.projectId, status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                ref.read(taskListProvider(widget.projectId).notifier).moveTask(details.data, status);
              },
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isHovering ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isHovering
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) => _buildKanbanCard(context, tasks[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(BuildContext context, TaskModel task) {
    return Draggable<String>(
      data: task.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 260,
          child: _kanbanCardContent(task).animate().scaleXY(begin: 1.05, end: 1.05),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: _kanbanCardContent(task)),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '${Routes.taskDetail}/${widget.projectId}/${task.id}'),
        child: _kanbanCardContent(task),
      ),
    );
  }

  Widget _kanbanCardContent(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _priorityDot(task.priority),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
            if (task.assignedToName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                    child: Icon(LucideIcons.user, size: 8, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(width: 6),
                  Text(task.assignedToName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _priorityLabel(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _priorityColor(priority).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _priorityColor(priority))),
    );
  }

  Widget _priorityDot(String priority) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: _priorityColor(priority), shape: BoxShape.circle));
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'CRITICAL':
      case 'URGENT':
      case 'HIGH':
        return AppColors.danger;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  Widget _statusLabel(String status) {
    final label = AppColors.statusLabel(status);
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
