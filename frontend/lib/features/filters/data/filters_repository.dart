import 'package:dio/dio.dart';

class FiltersRepository {
  FiltersRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>?> fetch() async {
    final response = await _dio.get('/filters/couple');
    return response.data as Map<String, dynamic>?;
  }

  Future<void> save(Map<String, dynamic> filter) {
    return _dio.put('/filters/couple', data: filter);
  }
}
