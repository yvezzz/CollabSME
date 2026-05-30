import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_helper.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../widgets/glass_container.dart';
import '../../widgets/status_badge.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import './my_tasks_screen.dart';
import './team_screen.dart';
import './calendar_screen.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../widgets/project_activity_chart.dart';
import '../../widgets/app_toast.dart';

import 'reports_screen.dart';
import 'company_settings_screen.dart';
import 'global_search_delegate.dart';

/// Tableau de bord principal de l'application.
/// Affiche la barre latérale, les statistiques et les projets actifs.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Index pour gérer l'onglet actif
  int _selectedIndex = 0;

  bool _canViewScreen(int index, UserModel? user) {
    if (user == null) return true;
    if (index == 2) return user.isCompanyAdmin || user.role != 'MEMBER';
    if (index == 6) return user.isCompanyAdmin;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Écoute des données asynchrones (Riverpod)
    final projectsAsync = ref.watch(projectListProvider);
    final authAsync = ref.watch(authStateProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);


    final user = authAsync.value;

    if (!_canViewScreen(_selectedIndex, user)) {
      _selectedIndex = 0;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 800 && screenWidth <= 1200;

    // Contenu propre à chaque onglet
    final List<Widget> allPages = [
      _buildDashboard(projectsAsync, statsAsync, user, isDesktop, isTablet),
      const MyTasksScreen(),
      const TeamScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
      const ReportsScreen(),
      const CompanySettingsScreen(),
      const CalendarScreen(),
    ];

    final visibleIndices = [
      for (var i = 0; i < allPages.length; i++)
        if (_canViewScreen(i, user)) i,
    ];
    final pages = visibleIndices.map((i) => allPages[i]).toList();
    final visualIndex = visibleIndices.indexOf(_selectedIndex);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAIAssistant(),
        label: const Text("Assistant IA"),
        icon: const Icon(LucideIcons.sparkles),
        backgroundColor: AppColors.primary,
      ).animate().scale(delay: 1000.ms),
      body: Row(
        children: [
          if (isDesktop || isTablet) _buildSidebar(context, user),

          // Contenu dynamique basé sur l'index
          Expanded(child: IndexedStack(index: visualIndex >= 0 ? visualIndex : 0, children: pages)),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? BottomNavigationBar(
              currentIndex: visualIndex >= 0 ? visualIndex : 0,
              onTap: (vIndex) =>
                  setState(() => _selectedIndex = visibleIndices[vIndex]),
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              items: visibleIndices.map((i) {
                const items = [
                  BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: "Accueil"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.checkSquare), label: "Tâches"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: "Équipe"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.bell), label: "Notifications"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: "Paramètres"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.barChart3), label: "Rapports"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.building2), label: "Entreprise"),
                  BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: "Calendrier"),
                ];
                return items[i];
              }).toList(),
            )
          : null,
    );
  }

  void _showAIAssistant() {
    Navigator.of(context).pushNamed(Routes.aiAssistant);
  }

  /// Le tableau de bord principal
  Widget _buildDashboard(
    AsyncValue<List<ProjectModel>> projectsAsync,
    AsyncValue<DashboardStats> statsAsync,
    UserModel? user,
    bool isDesktop,
    bool isTablet,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectListProvider);
        ref.invalidate(dashboardStatsProvider);
      },
      child: CustomScrollView(
        slivers: [
          _buildAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(isDesktop, statsAsync),
                  const SizedBox(height: 32),
                  const ProjectActivityChart(),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Projets Actifs",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user != null &&
                          (user.isCompanyAdmin || user.role != 'MEMBER'))
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/projects/create'),
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text("Nouveau Projet"),
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
                  ),
                  const SizedBox(height: 24),

                  // Gestion des différents états de chargement des données
                  projectsAsync.when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                LucideIcons.folderOpen,
                                size: 64,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Aucun projet trouvé",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return _buildProjectCard(context, project)
                              .animate()
                              .fadeIn(delay: (100 * index).ms)
                              .slideY(begin: 0.1, end: 0);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, s) => Center(
                      child: Column(
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Erreur: ${e.toString().replaceAll("Exception: ", "")}",
                          ),
                          TextButton(
                            onPressed: () => ref.refresh(projectListProvider),
                            child: const Text("Réessayer"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, UserModel? user) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull;
    return Container(
      width: 72,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _selectedIndex = 0),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.layout, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 32),
          _sidebarIcon(LucideIcons.home, "Tableau de bord", index: 0),
          const SizedBox(height: 4),
          _sidebarIcon(LucideIcons.calendar, "Calendrier", index: 7),
          const SizedBox(height: 4),
          _sidebarIcon(LucideIcons.checkSquare, "Mes Tâches", index: 1),
          if (_canViewScreen(2, user)) ...[
            const SizedBox(height: 4),
            _sidebarIcon(LucideIcons.users, "Équipe", index: 2),
          ],
          const SizedBox(height: 4),
          _sidebarIcon(LucideIcons.bell, "Notifications", index: 3, badgeCount: unreadCount),
          const SizedBox(height: 4),
          _sidebarIcon(LucideIcons.barChart3, "Rapports", index: 5),
          if (_canViewScreen(6, user)) ...[
            const SizedBox(height: 4),
            _sidebarIcon(LucideIcons.building2, "Entreprise", index: 6),
          ],
          const SizedBox(height: 4),
          _sidebarIcon(LucideIcons.settings, "Paramètres", index: 4),
          const Spacer(),
          InkWell(
            onTap: () => setState(() => _selectedIndex = 4),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  (user != null && user.fullName.isNotEmpty)
                      ? user.fullName[0].toUpperCase()
                      : "U",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, String tooltip, {required int index, int? badgeCount}) {
    final active = _selectedIndex == index;
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 72,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: active
                ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: -14,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeCount > 99 ? "99+" : "$badgeCount",
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(UserModel? user) {
    return SliverAppBar(
      backgroundColor: AppColors.background.withValues(alpha: 0.8),
      floating: true,
      pinned: true,
      elevation: 0,
      title: LayoutBuilder(
        builder: (context, constraints) => Text(
          constraints.maxWidth < 200
              ? "Bonjour"
              : "Bon retour, ${user?.firstName ?? user?.fullName.split(' ')[0] ?? 'Utilisateur'}",
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showNotifSnackBar(),
          icon: const Icon(LucideIcons.bell),
        ),
        IconButton(
          onPressed: () => _showSearchSnackBar(),
          icon: const Icon(LucideIcons.search),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  void _showNotifSnackBar() {
    setState(() => _selectedIndex = 3);
  }

  void _showSearchSnackBar() {
    showSearch(
      context: context,
      delegate: GlobalSearchDelegate(ref: ref),
    );
  }

  Widget _buildStatsRow(bool isDesktop, AsyncValue statsAsync) {
    return statsAsync.when(
      data: (stats) => isDesktop
          ? Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Projets",
                    stats.totalProjects.toString(),
                    LucideIcons.briefcase,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Tâches",
                    stats.activeTasks.toString(),
                    LucideIcons.checkCircle,
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Équipe",
                    stats.teamMembers.toString(),
                    LucideIcons.users,
                    AppColors.accent,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildStatCard(
                  "Projets",
                  stats.totalProjects.toString(),
                  LucideIcons.briefcase,
                  AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  "Tâches",
                  stats.activeTasks.toString(),
                  LucideIcons.checkCircle,
                  AppColors.accent,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  "Équipe",
                  stats.teamMembers.toString(),
                  LucideIcons.users,
                  AppColors.accent,
                ),
              ],
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text("Erreur stats"),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProjectAction(BuildContext context, ProjectModel project) {
    final user = ref.read(authStateProvider).value;
    final isAdmin = user?.isCompanyAdmin ?? false;
    final isLead = isAdmin || user?.role == 'LEAD';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.pencil, color: Colors.white),
              title: const Text("Modifier"),
              onTap: () { Navigator.pop(ctx); _showEditDialog(project.id); },
            ),
            ListTile(
              leading: const Icon(LucideIcons.users, color: Colors.white),
              title: const Text("Membres"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(
                  '${Routes.projectMembers}/${project.id}',
                );
              },
            ),
            if (isLead && project.status == 'DRAFT')
              ListTile(
                leading: const Icon(LucideIcons.play, color: AppColors.accent),
                title: const Text("Activer"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmProjectAction(context, project.id, 'activate',
                    "Activer le projet ?", "Le projet passera en statut ACTIF.");
                },
              ),
            if (isLead && project.status == 'ACTIVE')
              ListTile(
                leading: const Icon(LucideIcons.checkCircle, color: AppColors.primary),
                title: const Text("Valider"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmProjectAction(context, project.id, 'validate',
                    "Valider le projet ?", "Le projet sera marqué comme terminé.");
                },
              ),
            if (isLead && project.status != 'ARCHIVED')
              ListTile(
                leading: const Icon(LucideIcons.archive, color: AppColors.warning),
                title: const Text("Archiver"),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmProjectAction(context, project.id, 'archive',
                    "Archiver le projet ?", "Le projet sera archivé.");
                },
              ),
            if (isAdmin)
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppColors.danger),
                title: const Text("Supprimer", style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteProject(context, project.id);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String projectId) {
    final projectAsync = ref.read(singleProjectProvider(projectId));
    projectAsync.whenData((project) {
      Navigator.pushNamed(context, '${Routes.projectEdit}/', arguments: project);
    });
  }

  Future<void> _confirmProjectAction(
    BuildContext context, String projectId, String action,
    String title, String message,
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
    if (confirm == true) {
      try {
        await ref.read(singleProjectProvider(projectId).notifier).updateStatus(action);
        if (context.mounted) {
          AppToast.show(context, message: "Statut mis à jour", type: ToastType.success);
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
        }
      }
    }
  }

  Future<void> _confirmDeleteProject(BuildContext context, String projectId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Supprimer le projet", style: TextStyle(color: AppColors.danger)),
        content: const Text("Action irréversible. Toutes les tâches et données seront supprimées."),
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
    if (confirm == true) {
      try {
        await ref.read(projectRepositoryProvider).deleteProject(projectId);
        if (context.mounted) {
          AppToast.show(context, message: "Projet supprimé", type: ToastType.success);
          ref.invalidate(projectListProvider);
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
        }
      }
    }
  }

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('${Routes.projectDetails}/${project.id}'),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: project.status),
                  GestureDetector(
                    onTap: () => _handleProjectAction(context, project),
                    child: const Icon(
                      LucideIcons.moreHorizontal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _buildProgressBar(project.progress),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    LucideIcons.users,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${project.memberCount} membres",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Créé le ${_formatDate(project.createdAt)}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Progression",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          borderRadius: BorderRadius.circular(10),
          minHeight: 6,
        ),
      ],
    );
  }

}

/// Délégué pour la recherche de projets
class ProjectSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  ProjectSearchDelegate({required this.ref});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(LucideIcons.x), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final projectsAsync = ref.watch(projectListProvider);

    return projectsAsync.when(
      data: (projects) {
        final results = projects
            .where(
              (p) =>
                  p.title.toLowerCase().contains(query.toLowerCase()) ||
                  (p.key?.toLowerCase().contains(query.toLowerCase()) ?? false),
            )
            .toList();

        if (results.isEmpty) {
          return const Center(child: Text("Aucun projet correspondant."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final project = results[index];
            return ListTile(
              leading: const Icon(
                LucideIcons.briefcase,
                color: AppColors.primary,
              ),
              title: Text(project.title),
              subtitle: Text(project.key ?? ""),
              onTap: () {
                close(context, null);
                Navigator.of(context).pushNamed('${Routes.projectDetails}/${project.id}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Erreur: $e")),
    );
  }
}
