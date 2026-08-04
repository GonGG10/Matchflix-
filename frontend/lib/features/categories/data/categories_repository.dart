import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/category_entity.dart';

class CategoriesRepository {
  CategoriesRepository(this._dio);
  final Dio _dio;

  Future<List<CategoryEntity>> findAll() async {
    final response = await _dio.get(ApiEndpoints.categories);
    return (response.data as List)
        .map((e) => CategoryEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setForCouple(List<String> categoryIds) {
    return _dio.put(ApiEndpoints.coupleCategories, data: {'categoryIds': categoryIds});
  }
}
