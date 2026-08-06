import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/movies_repository.dart';
import '../../domain/movie_entity.dart';

final moviesRepositoryProvider = Provider((ref) => MoviesRepository(ref.watch(dioProvider)));

class _Sentinel { const _Sentinel(); }
const _sentinel = _Sentinel();

class SwipeState {
  const SwipeState({
    this.currentMovie,
    this.nextMovie,
    this.isLoading = true,
    this.matchedMovie,
    this.noMoreMovies = false,
    this.errorMessage,
    this.matchCount = 0,
    this.maxMatchesReached = false,
  });

  final MovieEntity? currentMovie;
  final MovieEntity? nextMovie;
  final bool isLoading;
  final MovieEntity? matchedMovie;
  final bool noMoreMovies;
  final String? errorMessage;
  final int matchCount;
  final bool maxMatchesReached;

  SwipeState copyWith({
    MovieEntity? currentMovie,
    Object? nextMovie = _sentinel,
    bool? isLoading,
    MovieEntity? matchedMovie,
    bool clearMatch = false,
    bool? noMoreMovies,
    String? errorMessage,
    bool clearError = false,
    int? matchCount,
    bool? maxMatchesReached,
  }) {
    return SwipeState(
      currentMovie: currentMovie ?? this.currentMovie,
      nextMovie: identical(nextMovie, _sentinel) ? this.nextMovie : nextMovie as MovieEntity?,
      isLoading: isLoading ?? this.isLoading,
      matchedMovie: clearMatch ? null : (matchedMovie ?? this.matchedMovie),
      noMoreMovies: noMoreMovies ?? this.noMoreMovies,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      matchCount: matchCount ?? this.matchCount,
      maxMatchesReached: maxMatchesReached ?? this.maxMatchesReached,
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

  /// IDs de películas ya vistas en esta sesión.
  final Set<String> _swipedIds = {};
  bool _isSwiping = false;

  Future<void> _bootstrap() async {
    try {
      _swipedIds.clear();
      final first = await _repository.fetchNext(excludeIds: []);
      if (first != null) _swipedIds.add(first.id);
      final second = first == null
          ? null
          : await _repository.fetchNext(excludeIds: _swipedIds.toList());
      if (second != null) _swipedIds.add(second.id);

      state = SwipeState(
        currentMovie: first,
        nextMovie: second,
        isLoading: false,
        noMoreMovies: first == null,
      );
      if (first != null) {
        _connectRealtime();
      }
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo conectar. Comprueba tu conexión e inténtalo de nuevo.',
      );
    }
  }

  Future<void> retry() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _bootstrap();
  }

  /// Reinicia todo: borra swipes en el backend y recarga desde cero.
  Future<void> refresh() async {
    _isSwiping = false;
    state = const SwipeState(isLoading: true);
    try {
      await _repository.resetSwipes();
    } catch (_) {}
    await _bootstrap();
  }

  void _connectRealtime() async {
    final token = await _tokenStorage.read();
    if (token == null) return;
    try {
      final repo = _ref.read(roomsRepositoryProvider);
      final status = await repo.getRoomStatus();
      final coupleId = status['inviteCode'] as String?; // Use inviteCode as room identifier
      final hasRoom = status['hasRoom'] as bool? ?? false;
      if (!hasRoom) return;
      // The backend socket uses coupleId from the JWT, we just need to connect
      _ref.read(socketServiceProvider).connect(
            token: token,
            coupleId: coupleId ?? '',
            onMatch: (data) {
              final movie = MovieEntity.fromJson(data['movie'] as Map<String, dynamic>);
              final matchCount = data['matchCount'] as int? ?? 0;
              final maxReached = data['maxMatchesReached'] as bool? ?? false;
              state = state.copyWith(
                matchedMovie: movie,
                matchCount: matchCount,
                maxMatchesReached: maxReached,
              );
            },
          );
    } catch (_) {}
  }

  void dismissMatch() => state = state.copyWith(clearMatch: true);

  Future<void> swipe({required bool liked}) async {
    if (_isSwiping) return;
    final movie = state.currentMovie;
    if (movie == null) return;

    _isSwiping = true;

    // Registrar localmente
    _swipedIds.add(movie.id);

    // Avanzar a la siguiente carta
    final upcoming = state.nextMovie;
    state = state.copyWith(
      currentMovie: upcoming,
      nextMovie: null, // sentinel permite null
      noMoreMovies: upcoming == null,
    );

    // Enviar swipe al backend (await para que quede registrado)
    try {
      await _repository.sendSwipe(movieId: movie.id, liked: liked);
    } catch (_) {}

    // Precargar la siguiente carta, excluyendo TODAS las ya vistas
    if (upcoming != null) {
      final preloaded = await _repository.fetchNext(excludeIds: _swipedIds.toList());
      if (preloaded != null) _swipedIds.add(preloaded.id);
      state = state.copyWith(nextMovie: preloaded);
    }

    _isSwiping = false;
  }
}

final swipeControllerProvider = StateNotifierProvider<SwipeController, SwipeState>((ref) {
  return SwipeController(
    ref.watch(moviesRepositoryProvider),
    ref.watch(tokenStorageProvider),
    ref,
  );
});
