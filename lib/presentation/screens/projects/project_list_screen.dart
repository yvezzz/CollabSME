import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collabsme/data/models/project_model.dart';
import 'package:collabsme/data/repositories/project_repository.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/project_provider.dart';
import '../../providers/notification_provider.dart';
import 'project_details_screen.dart';
import 'package:collabsme/presentation/screens/home/notifications_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_helper.dart';
import '../../../widgets/glass_container.dart';
import '../../widgets/status_badge.dart';
import '../../providers/auth_provider.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateProjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final keyController = TextEditingController();
    final budgetController = TextEditingController();
    String selectedPriority = 'MEDIUM';
    Map<String, dynamic>? selectedTemplate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => FutureBuilder<List<Map<String, dynamic>>>(
          future: ProjectRepository().getTemplates(),
          builder: (context, snapshot) {
            final templates = snapshot.data ?? [];

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                selectedTemplate != null
                    ? '${selectedTemplate!['icon']} ${selectedTemplate!['name']}'
                    : "Nouveau Projet",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (templates.isNotEmpty && selectedTemplate == null) ...[
                      Text(
                        "OU PARTIR D'UN MODÈLE",
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: templates.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final t = templates[i];
                            return GestureDetector(
                              onTap: () => setDialogState(() => selectedTemplate = t),
                              child: Container(
                                width: 130,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(t['icon'] ?? '📁', style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 6),
                                    Text(
                                      t['name'] ?? '',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${(t['tasks'] as List?)?.length ?? 0} tâches",
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: AppColors.textSecondary),
                      ),
                      const Text(
                        "OU CRÉER À PARTIR DE ZÉRO",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Nom du projet *",
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textSecondary),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    if (selectedTemplate == null) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: keyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Clé du projet (ex: PRJ-001)",
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.textSecondary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Description",
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.textSecondary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPriority,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Priorité",
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.textSecondary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Basse')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Moyenne')),
                          DropdownMenuItem(value: 'HIGH', child: Text('Haute')),
                          DropdownMenuItem(value: 'CRITICAL', child: Text('Critique')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedPriority = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: budgetController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Budget (FCFA)",
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.textSecondary),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (selectedTemplate != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        "Le projet sera créé avec ${(selectedTemplate!['tasks'] as List).length} tâches pré-définies.",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => selectedTemplate = null),
                        icon: const Icon(LucideIcons.arrowLeft, size: 16),
                        label: const Text("Choisir un autre modèle"),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler", style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      if (selectedTemplate != null) {
                        ref
                            .read(projectListProvider.notifier)
                            .createFromTemplate(
                              templateId: selectedTemplate!['id'],
                              title: nameController.text.trim(),
                            );
                      } else {
                        ref
                            .read(projectListProvider.notifier)
                            .addProject(
                              title: nameController.text.trim(),
                              description: descController.text.trim(),
                              key: keyController.text.trim().isEmpty ? null : keyController.text.trim(),
                              priority: selectedPriority,
                              budget: budgetController.text.trim().isEmpty ? null : double.tryParse(budgetController.text.trim()),
                            );
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(selectedTemplate != null ? "Créer à partir du modèle" : "Créer"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectListProvider);
    final notifier = ref.read(projectListProvider.notifier);
    final user = ref.watch(authStateProvider).value;
    final canCreate =
        user != null && (user.isCompanyAdmin || user.role != 'MEMBER');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Projets",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildNotificationIcon(context),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateProjectDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: Column(
        children: [
          _buildSearchBar(notifier),
          Expanded(
            child: projectState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Erreur: $err")),
              data: (projects) {
                if (projects.isEmpty) {
                  return _buildEmptyState(context, canCreate);
                }
                return RefreshIndicator(
                  onRefresh: () => notifier.fetchProjects(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: projects.length + (notifier.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == projects.length) {
                        return _buildLoadMoreButton(notifier);
                      }
                      final project = projects[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '${Routes.projectDetails}/${project.id}'),
                        child: _buildProjectCard(
                          project,
                        ).animate().fadeIn(delay: (100 * index).ms).scale(),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ProjectListNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => notifier.search(v),
        decoration: InputDecoration(
          hintText: "Rechercher un projet...",
          prefixIcon: const Icon(LucideIcons.search, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    notifier.search('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(ProjectListNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton.icon(
          onPressed: () => notifier.loadMore(),
          icon: const Icon(LucideIcons.chevronDown, size: 18),
          label: Text("Voir plus (${notifier.totalCount - 20} restants)"),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.bell, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text("Notifications"),
                    backgroundColor: Colors.transparent,
                  ),
                  body: const NotificationsScreen(),
                ),
              ),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  LucideIcons.layout,
                  size: 20,
                  color: AppColors.primary,
                ),
                StatusBadge(status: project.status),
              ],
            ),
            const Spacer(),
            Text(
              project.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canCreate) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.folderOpen,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun projet trouvé",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (canCreate) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showCreateProjectDialog(context),
              child: const Text("Créer votre premier projet"),
            ),
          ],
        ],
      ),
    );
  }
}
