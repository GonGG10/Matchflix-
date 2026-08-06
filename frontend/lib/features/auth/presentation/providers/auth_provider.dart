import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_entity.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(dioProvider)));

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserEntity? user, bool? isLoading, String? error}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? false,
        error: error,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._tokenStorage) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final user = await _repository.me();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      await _tokenStorage.clear();
      state = const AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Resetear sesión anterior: borra couple, swipes y matches
      final result = await _repository.login(email, password);
      await _tokenStorage.save(result.token);
      try {
        await _repository.resetSession();
        // Tras reset, el user ya no tiene coupleId
        state = state.copyWith(
          user: result.user.copyWith(coupleId: null, coupleStatus: null),
          isLoading: false,
        );
      } catch (_) {
        // Si falla el reset, continuar con la sesión normal
        state = state.copyWith(user: result.user, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.register(email, password, displayName);
      await _tokenStorage.save(result.token);
      state = state.copyWith(user: result.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  void setCoupleId(String coupleId) {
    if (state.user == null) return;
    state = state.copyWith(user: state.user!.copyWith(coupleId: coupleId));
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = const AuthState();
  }

  String _friendlyError(Object e) => 'No se pudo completar la operación. Comprueba tus datos e inténtalo de nuevo.';
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(tokenStorageProvider));
});
