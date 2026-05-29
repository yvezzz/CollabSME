import 'package:collabsme/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_container.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  bool _isSavingProfile = false;
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authStateProvider).value;
    if (user?.preferences != null &&
        user!.preferences!.containsKey('notifications_enabled')) {
      _notificationsEnabled =
          user.preferences!['notifications_enabled'] as bool;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber ?? '';
    _bioController.text = user.bio ?? '';
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.15 : 16.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Paramètres",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Personnalisez votre expérience CollabSME.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Profile Section
                _sectionTitle("PROFIL"),
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  (user?.fullName.isNotEmpty == true)
                                      ? user!.fullName.substring(0, 1).toUpperCase()
                                      : "U",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? "Utilisateur",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      softWrap: true,
                                    ),
                                    Text(
                                      user?.email ?? "",
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                      softWrap: true,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        _infoBadge(user?.displayRole ?? "Membre", AppColors.primary),
                                        if (user?.isCompanyAdmin == true)
                                          _infoBadge("Admin", AppColors.accent),
                                      ],
                                    ),
                                    if (!_isEditing && user != null && (user.bio?.isNotEmpty == true)) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        user.bio!,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        softWrap: true,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.pencil,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: _startEditing,
                                  tooltip: "Modifier",
                                ),
                            ],
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _firstNameController,
                                    label: "Prénom",
                                    icon: LucideIcons.user,
                                    formatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-ZÀ-ÿ\s]'),
                                      ),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return "Prénom requis";
                                      }
                                      if (v.length < 2) {
                                        return "Prénom trop court";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppTextField(
                                    controller: _lastNameController,
                                    label: "Nom",
                                    icon: LucideIcons.user,
                                    formatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-ZÀ-ÿ\s]'),
                                      ),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return "Nom requis";
                                      }
                                      if (v.length < 2) {
                                        return "Nom trop court";
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _phoneController,
                              label: "Téléphone",
                              icon: LucideIcons.phone,
                              formatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\s\+\-\(\)]'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _bioController,
                              label: "Bio",
                              icon: LucideIcons.info,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: TextEditingController(
                                      text: user?.email ?? '',
                                    ),
                                    label: "E-mail",
                                    icon: LucideIcons.mail,
                                    enabled: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSavingProfile
                                        ? null
                                        : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSavingProfile
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            "Enregistrer",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _cancelEditing,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: AppColors.textSecondary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      "Annuler",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                _sectionTitle("MEMBRES"),
                _buildSettingItem(
                  icon: LucideIcons.users,
                  title: "Gérer les membres",
                  subtitle: "Inviter, promouvoir, retirer des collaborateurs",
                  onTap: () => Navigator.of(context).pushNamed('/team'),
                ),

                const SizedBox(height: 32),
                _sectionTitle("PRÉFÉRENCES"),
                _buildSettingItem(
                  icon: LucideIcons.bell,
                  title: "Notifications",
                  subtitle: "Activer ou désactiver les notifications",
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) async {
                      setState(() => _notificationsEnabled = v);
                      try {
                        await ref
                            .read(authStateProvider.notifier)
                            .updateProfile(
                              preferences: {'notifications_enabled': v},
                            );
                      } catch (_) {}
                      if (!context.mounted) return;
                      AppToast.show(
                        context,
                        message: v
                            ? "Notifications activées"
                            : "Notifications désactivées",
                        type: ToastType.success,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 48),
                _buildLogoutButton(context),

                const SizedBox(height: 16),
                _buildDeleteAccountButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);
    try {
      await ref
          .read(authStateProvider.notifier)
          .updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
          );
      if (mounted) {
        setState(() => _isEditing = false);
        AppToast.show(
          context,
          message: "Profil mis à jour avec succès",
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: "Erreur lors de la mise à jour : $e",
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Supprimer mon compte",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.danger,
          ),
        ),
        content: const Text(
          "Cette action est irréversible. Toutes vos données seront définitivement supprimées.\n\nVoulez-vous vraiment continuer ?",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Dernière confirmation",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Êtes-vous absolument sûr ? Cette action ne peut pas être annulée.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() => _isDeletingAccount = true);
              try {
                await ref.read(authRepositoryProvider).deleteAccount();
                await ref.read(authStateProvider.notifier).logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
                if (!mounted) return;
                AppToast.show(
                  context,
                  message: "Compte supprimé avec succès",
                  type: ToastType.success,
                );
              } catch (e) {
                if (!mounted) return;
                AppToast.show(
                  context,
                  message: "Erreur : $e",
                  type: ToastType.error,
                );
              } finally {
                if (mounted) setState(() => _isDeletingAccount = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirmer la suppression"),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.primary, size: 20),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 16),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isDeletingAccount ? null : _showDeleteAccountDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
        ),
        icon: _isDeletingAccount
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.danger,
                ),
              )
            : const Icon(LucideIcons.trash2),
        label: Text(
          _isDeletingAccount ? "Suppression..." : "Supprimer mon compte",
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoggingOut
            ? null
            : () async {
                final success = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text("Déconnexion"),
                    content: const Text(
                      "Voulez-vous vraiment vous déconnecter ?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Annuler"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Confirmer"),
                      ),
                    ],
                  ),
                );

                if (success == true) {
                  setState(() => _isLoggingOut = true);
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger.withValues(alpha: 0.1),
          foregroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoggingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.danger,
                ),
              )
            : const Icon(LucideIcons.logOut),
        label: Text(_isLoggingOut ? "Déconnexion..." : "Déconnexion"),
      ),
    );
  }
}
