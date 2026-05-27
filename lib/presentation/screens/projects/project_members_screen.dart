import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:collabsme/data/repositories/project_member_repository.dart';
import 'package:collabsme/data/repositories/user_repository.dart';
import 'package:collabsme/data/models/project_member_model.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/core/network/api_client.dart';
import 'package:collabsme/core/constants/app_constants.dart';

class ProjectMembersScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectMembersScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectMembersScreen> createState() =>
      _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends ConsumerState<ProjectMembersScreen> {
  final _memberRepo = ProjectMemberRepository();
  final _userRepo = UserRepository();
  List<ProjectMemberModel>? _members;
  List<UserModel>? _companyUsers;
  List<Map<String, dynamic>> _workload = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _loadingMemberIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _memberRepo.getProjectMembers(widget.projectId),
        _userRepo.getCompanyUsers(),
        ApiClient.get('projects/${widget.projectId}/workload/'),
      ]);
      if (mounted) {
        setState(() {
          _members = results[0] as List<ProjectMemberModel>;
          _companyUsers = results[1] as List<UserModel>;
          final workloadResp = results[2] as http.Response;
          if (workloadResp.statusCode == 200) {
            _workload = List<Map<String, dynamic>>.from(jsonDecode(workloadResp.body));
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<UserModel> get _availableUsers {
    if (_members == null || _companyUsers == null) return [];
    final memberIds = _members!.map((m) => m.userId).toSet();
    return _companyUsers!.where((u) => !memberIds.contains(u.id)).toList();
  }

  Future<void> _addMember(String userId) async {
    try {
      await _memberRepo.addMember(projectId: widget.projectId, userId: userId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur: $e",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Retirer ce membre ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Retirer",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loadingMemberIds.add(memberId));
    try {
      await _memberRepo.removeMember(widget.projectId, memberId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur: $e",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMemberIds.remove(memberId));
    }
  }

  Future<void> _toggleRole(ProjectMemberModel member) async {
    final newRole = member.role == 'LEAD' ? 'MEMBER' : 'LEAD';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          newRole == 'LEAD'
              ? "Promouvoir chef d'équipe ?"
              : "Rétrograder en membre ?",
        ),
        content: Text(
          newRole == 'LEAD'
              ? "${member.userFullName} deviendra chef d'équipe."
              : "${member.userFullName} deviendra membre.",
        ),
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
    if (confirm != true) return;
    setState(() => _loadingMemberIds.add(member.id));
    try {
      await _memberRepo.updateMemberRole(widget.projectId, member.id, newRole);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur: $e",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMemberIds.remove(member.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          "Membres du projet",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_availableUsers.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.userPlus),
              tooltip: "Ajouter un membre",
              onSelected: _addMember,
              itemBuilder: (_) => _availableUsers
                  .map(
                    (u) => PopupMenuItem(
                      value: u.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.fullName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  u.email,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            Text(
              "Erreur: $_error",
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_members == null || _members!.isEmpty) {
      return const Center(
        child: Text(
          "Aucun membre",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_workload.isNotEmpty) _buildWorkloadBanner(),
          const SizedBox(height: 12),
          ...List<Widget>.generate(_members!.length * 2 - 1, (index) {
          if (index.isOdd) return const Divider(height: 1, color: AppColors.card);
          final i = index ~/ 2;
          final member = _members![i];
          final isLoading = _loadingMemberIds.contains(member.id);
          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                member.userFullName.isNotEmpty
                    ? member.userFullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              member.userFullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              member.userEmail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member.role == 'LEAD'
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member.role == 'LEAD' ? "Chef d'équipe" : "Membre",
                    style: TextStyle(
                      fontSize: 11,
                      color: member.role == 'LEAD'
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
                  tooltip: "Changer le rôle",
                  onPressed: isLoading ? null : () => _toggleRole(member),
                ),
                IconButton(
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.userX, size: 18),
                  tooltip: "Retirer",
                  color: AppColors.danger,
                  onPressed: isLoading ? null : () => _removeMember(member.id),
                ),
              ],
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildWorkloadBanner() {
    final totalActive = _workload.fold<int>(0, (sum, w) => sum + (w['active_tasks'] as int? ?? 0));
    final totalDone = _workload.fold<int>(0, (sum, w) => sum + (w['completed_tasks'] as int? ?? 0));
    final maxActive = _workload.fold<int>(0, (max, w) => (w['active_tasks'] as int? ?? 0) > max ? (w['active_tasks'] as int? ?? 0) : max);
    final overloaded = _workload.where((w) => (w['active_tasks'] as int? ?? 0) > 5).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.activity, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Charge de travail",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _workloadStat("Actives", "$totalActive", AppColors.warning),
              const SizedBox(width: 16),
              _workloadStat("Terminées", "$totalDone", AppColors.accent),
              const SizedBox(width: 16),
              _workloadStat("Max/membre", "$maxActive", AppColors.danger),
            ],
          ),
          if (overloaded.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "⚠ ${overloaded.length} membre(s) ont plus de 5 tâches actives",
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _workloadStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
