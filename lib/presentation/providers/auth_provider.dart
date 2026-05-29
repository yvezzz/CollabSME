import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collabsme/core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/exceptions/api_exception.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier(ref.watch(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;
  bool _checking = false;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    ApiClient.onSessionExpired = () {
      state = const AsyncValue.loading();
      checkSession();
    };
    checkSession();
  }

  Future<void> checkSession() async {
    if (_checking) return;
    _checking = true;
    try {
      final token = await ApiClient.getToken();
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }

      try {
        final user = await _repository.getMe();
        state = AsyncValue.data(user);
      } catch (e, stack) {
        // On ne supprime le token QUE si c'est une erreur d'authentification (401/403)
        // Si c'est une erreur réseau (ex: pas internet), on garde le token pour réessayer plus tard
        if (e is ApiException && (e.statusCode == 401 || e.statusCode == 403)) {
          await ApiClient.removeToken();
          state = const AsyncValue.data(null);
        } else {
          // Erreur réseau ou serveur : on passe en erreur mais on garde le token
          state = AsyncValue.error(e, stack);
        }
      }
    } finally {
      _checking = false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String companyName,
    String? phoneNumber,
  }) async {
    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        companyName: companyName,
        phoneNumber: phoneNumber,
      );
      // Auto login after registration
      return await login(email, password);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final updatedUser = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        bio: bio,
        preferences: preferences,
      );
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      // Profil inchangé en cas d'échec ; l'UI peut relancer via checkSession si besoin
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
