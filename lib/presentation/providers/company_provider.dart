import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collabsme/data/models/user_model.dart';
import 'package:collabsme/data/repositories/company_repository.dart';

import '../../data/repositories/invitation_repository.dart';

final companyRepositoryProvider = Provider((ref) => CompanyRepository());
final invitationRepositoryProvider = Provider((ref) => InvitationRepository());

final companyMembersProvider = StateNotifierProvider<CompanyMembersNotifier, AsyncValue<List<UserModel>>>((ref) {
  return CompanyMembersNotifier(ref.watch(companyRepositoryProvider));
});

final pendingInvitationsProvider = StateNotifierProvider<PendingInvitationsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PendingInvitationsNotifier(ref.watch(invitationRepositoryProvider));
});

class PendingInvitationsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final InvitationRepository _repository;
  Timer? _pollTimer;

  PendingInvitationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
  }

  Future<void> _silentRefresh() async {
    try {
      final invites = await _repository.getInvitations();
      if (mounted) state = AsyncValue.data(invites);
    } catch (_) {}
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final invites = await _repository.getInvitations();
      state = AsyncValue.data(invites);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _repository.cancelInvitation(id);
      await fetch();
    } catch (e) {
      debugPrint("Erreur annulation invitation: $e");
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

class CompanyMembersNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final CompanyRepository _repository;

  CompanyMembersNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    state = const AsyncValue.loading();
    try {
      final members = await _repository.getMembers();
      final uniqueMembers = <String, UserModel>{};
      for (final member in members) {
        uniqueMembers[member.id] = member;
      }
      state = AsyncValue.data(uniqueMembers.values.toList());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
