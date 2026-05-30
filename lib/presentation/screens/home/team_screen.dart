import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../utils/safe_parser.dart';
import '../../../widgets/glass_container.dart';
import '../../providers/company_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/company_repository.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import 'package:intl/intl.dart';

/// Écran de gestion de l'équipe et des collaborateurs.
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  String? _changingRoleUserId;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(companyMembersProvider);
    final currentUser = ref.watch(authStateProvider).value;
    final isAdmin = currentUser?.isCompanyAdmin == true;

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 32.0;
    final crossAxisCount = screenWidth > 1200 ? 4 : (screenWidth > 600 ? 2 : 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          "Équipe",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(LucideIcons.userPlus),
              tooltip: "Inviter",
              onPressed: () => _showInviteDialog(context, ref),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAdmin) const _PendingInvitationsPanel(),
            if (isAdmin) const SizedBox(height: 24),
            Expanded(
              child: membersAsync.when(
                data: (members) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(companyMembersProvider);
                  },
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: screenWidth < 600 ? 1.6 : 1.3,
                    ),
                    itemCount: members.length,
                    itemBuilder: (context, index) => _buildMemberCard(
                      context,
                      index,
                      members[index],
                      isAdmin,
                      currentUser?.id,
                      ref,
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text("Erreur: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String selectedRole = 'MEMBER';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Inviter un membre",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Envoyez une invitation par e-mail pour rejoindre votre organisation.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: emailController,
                  label: "E-mail du collaborateur",
                  icon: LucideIcons.mail,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "E-mail requis";
                    if (!RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(v.trim())) {
                      return "Format d'e-mail invalide";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Rôle",
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MEMBER', child: Text('Membre')),
                    DropdownMenuItem(
                      value: 'LEAD',
                      child: Text('Chef d\'équipe'),
                    ),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedRole = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text(
                "Annuler",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final email = emailController.text.trim();

                      setDialogState(() => isSubmitting = true);
                      try {
                        await ref
                            .read(invitationRepositoryProvider)
                            .sendInvitation(email, role: selectedRole);
                        if (context.mounted) {
                          Navigator.pop(context);
                          AppToast.show(
                            context,
                            message: "Invitation envoyée à $email !",
                            type: ToastType.success,
                          );
                          ref.invalidate(companyMembersProvider);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            message: "Erreur : ${e.toString()}",
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Envoyer"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    int index,
    UserModel member,
    bool isAdmin,
    String? currentUserId,
    WidgetRef ref,
  ) {
    final roleColor = member.isCompanyAdmin
        ? AppColors.primary
        : member.role == 'LEAD'
        ? AppColors.accent
        : AppColors.textSecondary;

    return GlassContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  member.fullName.isNotEmpty
                      ? member.fullName.substring(0, 1).toUpperCase()
                      : "?",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (member.isCompanyAdmin)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.shield,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            member.fullName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            member.displayRole,
            style: TextStyle(
              color: roleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isAdmin && member.id != currentUserId) ...[
            const SizedBox(height: 8),
            _buildRoleActions(context, member, ref),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _showRemoveMemberDialog(member),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.userX, size: 10, color: AppColors.danger),
                    SizedBox(width: 3),
                    Text("Retirer", style: TextStyle(fontSize: 10, color: AppColors.danger)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_socialIcon(LucideIcons.mail, member.email)],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).scale();
  }

  Widget _socialIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildRoleActions(
    BuildContext context,
    UserModel member,
    WidgetRef ref,
  ) {
    final isMember = member.role == 'MEMBER';
    final isLead = member.role == 'LEAD';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isMember)
          _roleActionButton(
            icon: LucideIcons.arrowUp,
            label: "Promouvoir Lead",
            color: AppColors.accent,
            loading: _changingRoleUserId == member.id,
            onTap: () => _changeRole(member.id, 'LEAD'),
          ),
        if (isLead)
          _roleActionButton(
            icon: LucideIcons.arrowDown,
            label: "Rétrograder Membre",
            color: AppColors.textSecondary,
            loading: _changingRoleUserId == member.id,
            onTap: () => _changeRole(member.id, 'MEMBER'),
          ),
      ],
    );
  }

  Widget _roleActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool loading = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: loading ? color.withValues(alpha: 0.5) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(String userId, String newRole) async {
    final action = newRole == 'LEAD' ? 'promu Lead' : 'rétrogradé Membre';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Changer le rôle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Confirmez-vous le changement de rôle ? L'utilisateur sera $action.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Annuler",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _changingRoleUserId = userId);
    try {
      await CompanyRepository().changeMemberRole(userId, newRole);
      ref.invalidate(companyMembersProvider);
      if (mounted) {
        AppToast.show(
          context,
          message: "Rôle mis à jour",
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _changingRoleUserId = null);
    }
  }

  void _showRemoveMemberDialog(UserModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Retirer le membre", style: TextStyle(color: AppColors.danger)),
        content: Text("Voulez-vous retirer ${member.fullName} de l'entreprise ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text("Retirer"),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      try {
        await CompanyRepository().removeMember(member.id);
        ref.invalidate(companyMembersProvider);
        if (mounted) {
          AppToast.show(context, message: "${member.fullName} a été retiré", type: ToastType.success);
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, message: "Erreur : $e", type: ToastType.error);
        }
      }
    });
  }
}

class _PendingInvitationsPanel extends ConsumerWidget {
  const _PendingInvitationsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(pendingInvitationsProvider);
    return invitationsAsync.when(
      data: (invites) {
        if (invites.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Invitations en attente",
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
            ),
            const SizedBox(height: 8),
            ...invites.where((invite) {
              final email = invite['email'] ?? invite['email_address'] ?? '';
              return email.isNotEmpty;
            }).map((invite) {
              final email = invite['email'] ?? invite['email_address'] ?? '';
              final id = invite['id']?.toString() ?? '';
              final createdAt = invite['created_at'] != null
                  ? DateFormat('dd/MM/yyyy').format(SafeParser.parseDateTime(invite['created_at']) ?? DateTime.now())
                  : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mail, size: 18, color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (createdAt.isNotEmpty)
                                Text("Envoyée le $createdAt", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(pendingInvitationsProvider.notifier).cancel(id),
                          child: const Text("Annuler", style: TextStyle(color: AppColors.danger, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
