import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collabsme/data/models/project_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/project_provider.dart';
import '../../providers/notification_provider.dart';
import 'project_details_screen.dart';
import 'package:collabsme/presentation/screens/home/notifications_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_container.dart';
import '../../widgets/status_badge.dart';
import '../../providers/auth_provider.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final keyController = TextEditingController();
    final budgetController = TextEditingController();
    String selectedPriority = 'MEDIUM';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Nouveau Projet",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    DropdownMenuItem(
                      value: 'CRITICAL',
                      child: Text('Critique'),
                    ),
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Annuler",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  ref
                      .read(projectListProvider.notifier)
                      .addProject(
                        title: nameController.text.trim(),
                        description: descController.text.trim(),
                        key: keyController.text.trim().isEmpty
                            ? null
                            : keyController.text.trim(),
                        priority: selectedPriority,
                        budget: budgetController.text.trim().isEmpty
                            ? null
                            : double.tryParse(budgetController.text.trim()),
                      );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Créer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectListProvider);
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
          _buildNotificationIcon(context, ref),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => _showCreateProjectDialog(context, ref),
              backgroundColor: AppColors.primary,
              child: const Icon(LucideIcons.plus),
            )
          : null,
      body: projectState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erreur: $err")),
        data: (projects) {
          if (projects.isEmpty) {
            return _buildEmptyState(context, ref, canCreate);
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(projectListProvider.notifier).fetchProjects(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProjectDetailsScreen(projectId: project.id),
                    ),
                  ),
                  child: _buildProjectCard(
                    project,
                  ).animate().fadeIn(delay: (100 * index).ms).scale(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.bell, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, bool canCreate) {
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
              onPressed: () => _showCreateProjectDialog(context, ref),
              child: const Text("Créer votre premier projet"),
            ),
          ],
        ],
      ),
    );
  }
}
