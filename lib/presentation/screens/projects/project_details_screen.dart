import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collabsme/core/constants/app_constants.dart';
import 'package:collabsme/core/network/route_helper.dart';
import 'package:collabsme/presentation/providers/task_provider.dart';
import 'package:collabsme/widgets/glass_container.dart';
import 'package:collabsme/data/models/task_model.dart';
import 'package:collabsme/presentation/providers/project_provider.dart';
import 'package:collabsme/data/models/project_model.dart';
import 'package:collabsme/presentation/widgets/app_toast.dart';
import 'package:collabsme/presentation/widgets/ai_chat_panel.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/status_badge.dart';

/// Vue détaillée d'un projet incluant le tableau Kanban et l'assistant IA.
class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(singleProjectProvider(widget.projectId));
    final tasksAsync = ref.watch(taskListProvider(widget.projectId));
    final user = ref.watch(authStateProvider).value;
    final projectStatus = projectAsync.valueOrNull?.status;
    final isLocked = projectStatus == 'COMPLETED' || projectStatus == 'ARCHIVED';
    final canCreate =
        user != null && !isLocked && (user.isCompanyAdmin || user.role != 'MEMBER');
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return projectAsync.when(
      data: (project) => Scaffold(
        drawer: isMobile
            ? Drawer(child: _buildProjectSidebar(context, canCreate: canCreate, isDrawer: true))
            : null,
        floatingActionButton: isMobile && canCreate
            ? FloatingActionButton(
                onPressed: () => _handleAddTask(),
                backgroundColor: AppColors.primary,
                child: const Icon(LucideIcons.plus, color: Colors.white),
              )
            : null,
        appBar: isMobile
            ? AppBar(
                backgroundColor: AppColors.surface,
                title: Text(
                  project.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  if (canCreate)
                    IconButton(
                      icon: const Icon(LucideIcons.plus, size: 20),
                      tooltip: "Ajouter une tâche",
                      onPressed: () => _handleAddTask(),
                    ),
                  StatusBadge(status: project.status),
                  const SizedBox(width: 4),
                  if (canCreate)
                    IconButton(
                      icon: const Icon(LucideIcons.pencil),
                      tooltip: "Modifier",
                      onPressed: () => _showEditDialog(),
                    ),
                  IconButton(
                    icon: const Icon(LucideIcons.users),
                    tooltip: "Membres",
                    onPressed: _navigateToMembers,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.sparkles),
                    tooltip: "Assistant IA",
                    onPressed: () => _showAIModal(context),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreHorizontal),
                    onSelected: (action) =>
                        _handleProjectAction(action, project),
                    itemBuilder: (_) => _buildActionMenuItems(project),
                  ),
                ],
              )
            : null,
        body: Row(
          children: [
                    if (!isMobile) _buildProjectSidebar(context, canCreate: canCreate),
            Expanded(
              child: Column(
                children: [
                  if (!isMobile) _buildProjectHeader(project, canCreate),
                  Expanded(
                    child: tasksAsync.when(
                      data: (tasks) =>
                          _buildKanbanBoard(tasks, isMobile: isMobile),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) =>
                          Center(child: Text("Erreur tâches : $e")),
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildAIAssistant(),
          ],
        ),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) =>
          Scaffold(body: Center(child: Text("Erreur projet : $e"))),
    );
  }

  void _showAIModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: AIChatPanel(
                showHeader: false,
                showClearButton: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSidebar(BuildContext context, {bool canCreate = false, bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 80,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          if (!isDrawer)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 48),
          _iconItem(LucideIcons.list, "Liste", active: true),
          _iconItem(
            LucideIcons.columns,
            "Board",
            onTap: () => Navigator.of(context).pushNamed('${Routes.taskBoard}/${widget.projectId}'),
          ),
          _iconItem(LucideIcons.users, "Membres", onTap: _navigateToMembers),
          if (canCreate)
            _iconItem(LucideIcons.settings, "Modifier", onTap: _showEditDialog),
          _spacerItem(),
          _iconItem(
            LucideIcons.activity,
            "Activité",
            onTap: () => Navigator.of(context).pushNamed('${Routes.activityLog}/${widget.projectId}'),
          ),
        ],
      ),
    );
  }

  Widget _spacerItem() {
    return const Spacer();
  }

  Widget _iconItem(
    IconData icon,
    String label, {
    bool active = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: active ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProjectHeader(ProjectModel project, bool canCreate) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (project.key != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          project.key!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        project.title,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                  softWrap: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildBudgetInfo(project),
          if (canCreate) ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _handleAddTask(),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text("Ajouter une tâche"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(
              LucideIcons.moreHorizontal,
              color: AppColors.textSecondary,
            ),
            onSelected: (action) => _handleProjectAction(action, project),
            itemBuilder: (_) => _buildActionMenuItems(project),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfo(ProjectModel project) {
    if (project.budget == null) return const SizedBox();
    final spent = project.actualCost;
    final progress = (spent / project.budget!).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "Budget: ${spent.toInt()} / ${project.budget!.toInt()} FCFA",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9
                  ? AppColors.danger
                  : (progress > 0.7 ? AppColors.warning : AppColors.accent),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddTask() async {
    try {
      final result = await Navigator.pushNamed(
        context,
        '${Routes.taskCreate}/${widget.projectId}',
        arguments: 'TODO',
      );
      if (result != null && mounted) {
        ref.invalidate(taskListProvider(widget.projectId));
      }
    } catch (e) {
      debugPrint("_handleAddTask error: $e");
    }
  }

  void _navigateToMembers() {
    Navigator.of(context).pushNamed('${Routes.projectMembers}/${widget.projectId}');
  }

  void _showEditDialog() {
    final projectAsync = ref.read(singleProjectProvider(widget.projectId));
    projectAsync.whenData((project) {
      Navigator.pushNamed(context, '${Routes.projectEdit}/', arguments: project);
    });
  }

  List<PopupMenuEntry<String>> _buildActionMenuItems(ProjectModel project) {
    final user = ref.read(authStateProvider).value;
    final isAdmin = user?.isCompanyAdmin ?? false;
    final isLead = isAdmin || user?.role == 'LEAD';
    final items = <PopupMenuEntry<String>>[];
    if (isLead) {
      items.add(
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(LucideIcons.pencil, size: 18),
            title: Text("Modifier"),
            dense: true,
          ),
        ),
      );
    }
    items.add(
      const PopupMenuItem(
        value: 'members',
        child: ListTile(
          leading: Icon(LucideIcons.users, size: 18),
          title: Text("Membres"),
          dense: true,
        ),
      ),
    );
    if (isLead) items.add(const PopupMenuDivider());
    if (isLead && project.status == 'DRAFT') {
      items.add(
        const PopupMenuItem(
          value: 'activate',
          child: ListTile(
            leading: Icon(LucideIcons.play, size: 18, color: AppColors.accent),
            title: Text("Activer"),
            dense: true,
          ),
        ),
      );
    }
    if (isLead && project.status == 'ACTIVE') {
      items.add(
        const PopupMenuItem(
          value: 'validate',
          child: ListTile(
            leading: Icon(
              LucideIcons.checkCircle,
              size: 18,
              color: AppColors.primary,
            ),
            title: Text("Valider / Clôturer"),
            dense: true,
          ),
        ),
      );
    }
    if (isLead && project.status != 'ARCHIVED') {
      items.add(
        const PopupMenuItem(
          value: 'archive',
          child: ListTile(
            leading: Icon(
              LucideIcons.archive,
              size: 18,
              color: AppColors.warning,
            ),
            title: Text("Archiver"),
            dense: true,
          ),
        ),
      );
    }
    if (isAdmin) {
      items.add(
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              LucideIcons.trash2,
              size: 18,
              color: AppColors.danger,
            ),
            title: Text("Supprimer", style: TextStyle(color: AppColors.danger)),
            dense: true,
          ),
        ),
      );
    }
    return items;
  }

  Future<void> _handleProjectAction(String action, ProjectModel project) async {
    switch (action) {
      case 'edit':
        _showEditDialog();
        break;
      case 'members':
        _navigateToMembers();
        break;
      case 'activate':
        await _confirmAndUpdateStatus(
          'activate',
          "Activer le projet ?",
          "Le projet passera en statut ACTIF.",
        );
        break;
      case 'validate':
        await _confirmAndUpdateStatus(
          'validate',
          "Valider le projet ?",
          "Le projet sera marqué comme terminé et validé.",
        );
        break;
      case 'archive':
        await _confirmAndUpdateStatus(
          'archive',
          "Archiver le projet ?",
          "Le projet sera archivé et n'apparaîtra plus dans la liste active.",
        );
        break;
      case 'delete':
        await _confirmAndDeleteProject(project);
        break;
    }
  }

  Future<void> _confirmAndDeleteProject(ProjectModel project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Supprimer le projet", style: TextStyle(color: AppColors.danger)),
        content: const Text("Cette action est irréversible. Le projet sera définitivement supprimé, ainsi que toutes ses tâches et données associées."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(widget.projectId);
        if (mounted) {
          AppToast.show(context, message: "Projet supprimé", type: ToastType.success);
          Navigator.of(context).pop(); // retour au tableau de bord
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
        }
      }
    }
  }

  Future<void> _confirmAndUpdateStatus(
    String action,
    String title,
    String message,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await ref
            .read(singleProjectProvider(widget.projectId).notifier)
            .updateStatus(action);
        if (mounted) {
          AppToast.show(
            context,
            message: "Statut mis à jour",
            type: ToastType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
        }
      }
    }
  }

  Widget _buildKanbanBoard(List<TaskModel> tasks, {bool isMobile = false}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumn(
            "À faire",
            tasks.where((t) => t.status == "TODO").toList(),
          ),
          _buildColumn(
            "En cours",
            tasks.where((t) => t.status == "IN_PROGRESS").toList(),
          ),
          _buildColumn(
            "Révision",
            tasks.where((t) => t.status == "REVIEW").toList(),
          ),
          _buildColumn(
            "Terminé",
            tasks.where((t) => t.status == "DONE").toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(String title, List<TaskModel> tasks) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 24),
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${tasks.length}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: tasks.map((task) => _buildTaskCard(task)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _priorityBadge(task.priority),
                  const Spacer(),
                  const Icon(
                    LucideIcons.moreHorizontal,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    LucideIcons.messageSquare,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${task.commentsCount}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    LucideIcons.paperclip,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "${task.attachmentsCount}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(
                      LucideIcons.user,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _priorityBadge(String priority) {
    Color color = priority == 'HIGH'
        ? AppColors.danger
        : (priority == 'MEDIUM' ? AppColors.warning : AppColors.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAIAssistant({bool isMobile = false}) {
    return Container(
      width: isMobile ? double.infinity : 350,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isMobile
            ? null
            : Border(
                left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
      ),
      child: AIChatPanel(
        showHeader: false,
        showClearButton: true,
      ),
    );
  }
}
