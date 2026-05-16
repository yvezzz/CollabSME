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

  PendingInvitationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetch();
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
      state = AsyncValue.data(members);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
