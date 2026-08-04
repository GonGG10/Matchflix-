import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';

class CoupleRepository {
  CoupleRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> create() async {
    final response = await _dio.post(ApiEndpoints.couples);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> join(String inviteCode) async {
    final response = await _dio.post(ApiEndpoints.joinCouple, data: {'inviteCode': inviteCode});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> myCouple() async {
    final response = await _dio.get(ApiEndpoints.myCouple);
    return response.data as Map<String, dynamic>;
  }
}
