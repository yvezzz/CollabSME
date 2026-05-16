import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/project_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../widgets/glass_container.dart';
import '../projects/project_details_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../../../presentation/widgets/app_toast.dart';
import '../auth/login_screen.dart';
import './my_tasks_screen.dart';
import './team_screen.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/dashboard_stats.dart';

import '../../widgets/project_activity_chart.dart';
import './ai_assistant_screen.dart';
import 'reports_screen.dart';
import 'company_settings_screen.dart';
import 'global_search_delegate.dart';
import '../../widgets/app_text_field.dart';

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
          Expanded(child: pages[visualIndex >= 0 ? visualIndex : 0]),
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
                switch (i) {
                  case 0:
                    return const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.home),
                      label: "Accueil",
                    );
                   case 1:
                    return const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.checkSquare),
                      label: "Tâches",
                    );
                  case 2:
                    return const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.users),
                      label: "Équipe",
                    );
                  case 3:
                    return const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.bell),
                      label: "Notifications",
                    );
                  case 4:
                    return const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.settings),
                      label: "Paramètres",
                    );
                  default:
                    return const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.barChart3),
                      label: "Plus",
                    );
                }
              }).toList(),
            )
          : null,
    );
  }

  void _showAIAssistant() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AIAssistantScreen()));
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
                          onPressed: () => _showNewProjectDialog(),
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

  /// Barre latérale de navigation
  Widget _buildSidebar(BuildContext context, UserModel? user) {
    return Container(
      width: 280,
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _selectedIndex = 0),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.layout, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  "CollabSME",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _sidebarItem(LucideIcons.home, "Tableau de bord", index: 0),
          _sidebarItem(LucideIcons.checkSquare, "Mes Tâches", index: 1),
          if (_canViewScreen(2, user))
            _sidebarItem(LucideIcons.users, "Équipe", index: 2),
          _sidebarItem(LucideIcons.bell, "Notifications", index: 3),
          _sidebarItem(LucideIcons.barChart3, "Rapports", index: 5),
          if (_canViewScreen(6, user))
            _sidebarItem(LucideIcons.building2, "Entreprise", index: 6),
          _sidebarItem(LucideIcons.settings, "Paramètres", index: 4),
          const Spacer(),
          // Profil utilisateur en bas de la sidebar
          InkWell(
            onTap: () => setState(() => _selectedIndex = 4),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (user?.fullName != null && user!.fullName.isNotEmpty)
                          ? user.fullName[0].toUpperCase()
                          : "U",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? "Utilisateur",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.displayRole ?? "Invité",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showLogoutDialog(),
                    icon: const Icon(LucideIcons.logOut, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, {required int index}) {
    final active = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewProjectDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final keyController = TextEditingController();
    final budgetController = TextEditingController();
    String priority = 'MEDIUM';
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nouveau Projet",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const Text(
                    "Lancez une nouvelle collaboration",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTextField(
                          controller: titleController,
                          label: "Titre du projet",
                          icon: LucideIcons.briefcase,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Titre requis" : null,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            AppTextField(
                              controller: keyController,
                              label: "Clé (ex: PROJ)",
                              icon: LucideIcons.key,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: priority,
                              dropdownColor: AppColors.surface,
                              decoration: InputDecoration(
                                labelText: "Priorité",
                                prefixIcon: const Icon(
                                  LucideIcons.alertTriangle,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                              ),
                              items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        p,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => priority = v!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: budgetController,
                          label: "Budget initial (€)",
                          icon: LucideIcons.dollarSign,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: descController,
                          label: "Description du projet",
                          icon: LucideIcons.fileText,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Annuler",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setDialogState(() => isSubmitting = true);
                                try {
                                  await ref
                                      .read(projectListProvider.notifier)
                                      .addProject(
                                        title: titleController.text.trim(),
                                        description: descController.text.trim(),
                                        key: keyController.text
                                            .trim()
                                            .toUpperCase(),
                                        priority: priority,
                                        budget: double.tryParse(
                                          budgetController.text,
                                        ),
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    AppToast.show(
                                      context,
                                      message: "Projet créé avec succès !",
                                      type: ToastType.success,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.show(
                                      context,
                                      message: "Erreur : $e",
                                      type: ToastType.error,
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => isSubmitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
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

  Widget _buildProjectCard(BuildContext context, ProjectModel project) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(projectId: project.id),
        ),
      ),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      project.status,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.moreHorizontal,
                    color: AppColors.textSecondary,
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.logOut,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Déconnexion",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(LucideIcons.logOut, size: 16),
            label: const Text("Se déconnecter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailsScreen(projectId: project.id),
                  ),
                );
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
