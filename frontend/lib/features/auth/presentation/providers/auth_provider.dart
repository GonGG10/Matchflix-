import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/user_entity.dart';

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  bool get isAuthenticated => user != null;
  AuthState copyWith({UserEntity? user, bool? isLoading, String? error}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._tokenStorage) : super(const AuthState());

  final TokenStorage _tokenStorage;

  Future<void> logout() async {
    await _tokenStorage.clear();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(tokenStorageProvider));
});
