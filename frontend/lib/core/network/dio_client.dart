import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'token_storage.dart';

/// Cliente Dio único para toda la app. Adjunta el JWT automáticamente y
/// redirige a login si el servidor responde 401.
class DioClient {
  DioClient(this._tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _tokenStorage.clear();
        }
        handler.next(error);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;
}
