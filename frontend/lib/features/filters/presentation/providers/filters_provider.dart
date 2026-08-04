import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../data/filters_repository.dart';

final filtersRepositoryProvider = Provider((ref) => FiltersRepository(ref.watch(dioProvider)));

class FilterFormState {
  const FilterFormState({this.maxDuration, this.minRating, this.mediaType});
  final int? maxDuration;
  final double? minRating;
  final String? mediaType; // MOVIE | SERIES | null (ambos)

  FilterFormState copyWith({int? maxDuration, double? minRating, String? mediaType, bool clearMediaType = false}) {
    return FilterFormState(
      maxDuration: maxDuration ?? this.maxDuration,
      minRating: minRating ?? this.minRating,
      mediaType: clearMediaType ? null : (mediaType ?? this.mediaType),
    );
  }

  Map<String, dynamic> toJson() => {
        if (maxDuration != null) 'maxDuration': maxDuration,
        if (minRating != null) 'minRating': minRating,
        if (mediaType != null) 'mediaType': mediaType,
      };
}

class FiltersController extends StateNotifier<FilterFormState> {
  FiltersController(this._repository) : super(const FilterFormState()) {
    _load();
  }
  final FiltersRepository _repository;

  Future<void> _load() async {
    final data = await _repository.fetch();
    if (data == null) return;
    state = FilterFormState(
      maxDuration: data['maxDuration'] as int?,
      minRating: (data['minRating'] as num?)?.toDouble(),
      mediaType: data['mediaType'] as String?,
    );
  }

  void setMaxDuration(int? value) => state = state.copyWith(maxDuration: value);
  void setMinRating(double? value) => state = state.copyWith(minRating: value);
  void setMediaType(String? value) =>
      state = value == null ? state.copyWith(clearMediaType: true) : state.copyWith(mediaType: value);

  Future<void> save() => _repository.save(state.toJson());
}

final filtersControllerProvider = StateNotifierProvider<FiltersController, FilterFormState>((ref) {
  return FiltersController(ref.watch(filtersRepositoryProvider));
});
