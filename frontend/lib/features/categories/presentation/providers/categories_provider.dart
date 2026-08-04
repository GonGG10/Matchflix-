import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../data/categories_repository.dart';
import '../../domain/category_entity.dart';

final categoriesRepositoryProvider = Provider((ref) => CategoriesRepository(ref.watch(dioProvider)));

final allCategoriesProvider = FutureProvider<List<CategoryEntity>>((ref) {
  return ref.watch(categoriesRepositoryProvider).findAll();
});

final selectedCategoryIdsProvider = StateProvider<Set<String>>((ref) => {});
