import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'dio_client.dart';
import '../realtime/socket_service.dart';

// Providers de infraestructura compartidos por toda la app.
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final tokenStorageProvider = Provider((ref) => TokenStorage(ref.watch(secureStorageProvider)));

final dioProvider = Provider<Dio>((ref) {
  return DioClient(ref.watch(tokenStorageProvider)).dio;
});

final socketServiceProvider = Provider((ref) => SocketService());
