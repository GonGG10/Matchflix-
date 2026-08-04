import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/user_entity.dart';

class AuthResult {
  AuthResult({required this.token, required this.user});
  final String token;
  final UserEntity user;
}

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  Future<AuthResult> login(String email, String password) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    return _parse(response.data);
  }

  Future<AuthResult> register(String email, String password, String displayName) async {
    final response = await _dio.post(ApiEndpoints.register, data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    return _parse(response.data);
  }

  Future<UserEntity> me() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserEntity.fromJson(response.data as Map<String, dynamic>);
  }

  AuthResult _parse(dynamic data) {
    return AuthResult(
      token: data['accessToken'] as String,
      user: UserEntity.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
