import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/movies_repository.dart';
import '../../domain/movie_entity.dart';

final moviesRepositoryProvider = Provider((ref) => MoviesRepository(ref.watch(dioProvider)));

class SwipeState {
  const SwipeState({
    this.currentMovie,
    this.nextMovie,
    this.isLoading = true,
    this.matchedMovie,
    this.noMoreMovies = false,
  });

  final MovieEntity? currentMovie;
  final MovieEntity? nextMovie; // precargada para que el swipe se sienta instantáneo
  final bool isLoading;
  final MovieEntity? matchedMovie; // no nulo mientras se muestra la animación de match
  final bool noMoreMovies;

  SwipeState copyWith({
    MovieEntity? currentMovie,
    MovieEntity? nextMovie,
    bool? isLoading,
    MovieEntity? matchedMovie,
    bool clearMatch = false,
    bool? noMoreMovies,
  }) {
    return SwipeState(
      currentMovie: currentMovie ?? this.currentMovie,
      nextMovie: nextMovie ?? this.nextMovie,
      isLoading: isLoading ?? this.isLoading,
      matchedMovie: clearMatch ? null : (matchedMovie ?? this.matchedMovie),
      noMoreMovies: noMoreMovies ?? this.noMoreMovies,
    );
  }
}

class SwipeController extends StateNotifier<SwipeState> {
  SwipeController(this._repository, this._tokenStorage, this._ref) : super(const SwipeState()) {
    _bootstrap();
  }

  final MoviesRepository _repository;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  Future<void> _bootstrap() async {
    final first = await _repository.fetchNext();
    final second = first == null ? null : await _repository.fetchNext();
    state = state.copyWith(
      currentMovie: first,
      nextMovie: second,
      isLoading: false,
      noMoreMovies: first == null,
    );
    _connectRealtime();
  }

  void _connectRealtime() async {
    final token = await _tokenStorage.read();
    final coupleId = _ref.read(authControllerProvider).user?.coupleId;
    if (coupleId == null || token == null) return;
    _ref.read(socketServiceProvider).connect(
          token: token,
          coupleId: coupleId,
          onMatch: (data) {
            final movie = MovieEntity.fromJson(data['movie'] as Map<String, dynamic>);
            state = state.copyWith(matchedMovie: movie);
          },
        );
  }

  void dismissMatch() => state = state.copyWith(clearMatch: true);

  Future<void> swipe({required bool liked}) async {
    final movie = state.currentMovie;
    if (movie == null) return;

    // Optimista: avanza a la carta siguiente inmediatamente y precarga otra más.
    final upcoming = state.nextMovie;
    state = state.copyWith(currentMovie: upcoming, nextMovie: null, noMoreMovies: upcoming == null);

    unawaited(_repository.sendSwipe(movieId: movie.id, liked: liked));

    if (upcoming != null) {
      final preloaded = await _repository.fetchNext();
      state = state.copyWith(nextMovie: preloaded);
    }
  }
}

final swipeControllerProvider = StateNotifierProvider<SwipeController, SwipeState>((ref) {
  return SwipeController(
    ref.watch(moviesRepositoryProvider),
    ref.watch(tokenStorageProvider),
    ref,
  );
});
