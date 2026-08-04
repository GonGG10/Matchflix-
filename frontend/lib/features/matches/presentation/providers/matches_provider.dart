import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../data/matches_repository.dart';
import '../../domain/match_entity.dart';

final matchesRepositoryProvider = Provider((ref) => MatchesRepository(ref.watch(dioProvider)));

final matchesListProvider = FutureProvider.autoDispose<List<MatchEntity>>((ref) {
  return ref.watch(matchesRepositoryProvider).findAll();
});
