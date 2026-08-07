import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/storage/seen_movies_storage.dart';
import '../../data/movies_repository.dart';
import '../../domain/movie_entity.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../filters/presentation/providers/filters_provider.dart';

final moviesRepositoryProvider = Provider((ref) => MoviesRepository(ref.watch(dioProvider)));

final seenMoviesStorageProvider = Provider((ref) => SeenMoviesStorage());

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
  SwipeController(this._repository, this._tokenStorage, this._ref, this._seenStorage) : super(const SwipeState()) {
    _bootstrap();
  }

  final MoviesRepository _repository;
  final TokenStorage _tokenStorage;
  final Ref _ref;
  final SeenMoviesStorage _seenStorage;

  /// IDs de películas ya vistas — cargados desde sessionStorage para persistir
  /// entre recreaciones del controlador y recargas de página.
  Set<String> _swipedIds = {};
  bool _isSwiping = false;

  /// Obtiene el mediaType actual desde la pantalla de categorías o filtros
  String? get _currentMediaType {
    try {
      // Primero intenta leer desde la selección de categorías
      final catMediaType = _ref.read(selectedMediaTypeProvider);
      if (catMediaType != null) return catMediaType;
      // Si no, lee desde los filtros guardados
      final filters = _ref.read(filtersControllerProvider);
      return filters.mediaType;
    } catch (_) {
      return null;
    }
  }

  /// Fetch con retry: si el backend devuelve una película ya vista,
  /// la añade a excludeIds y reintenta hasta 8 veces.
  Future<MovieEntity?> _fetchNextWithRetry({
    required Set<String> excludeIds,
    String? mediaType,
    int maxRetries = 8,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final movie = await _repository.fetchNext(
        excludeIds: excludeIds.toList(),
        mediaType: mediaType,
      );
      if (movie == null) return null;

      // Si la película ya fue vista, la añadimos a excludeIds Y a sessionStorage
      // para que el backend no la devuelva en el siguiente intento
      if (excludeIds.contains(movie.id)) {
        excludeIds.add(movie.id);
        _seenStorage.add(movie.id);
        continue;
      }

      return movie;
    }

    // Si después de todos los reintentos seguimos obteniendo repetidas,
    // devolvemos null (no hay más contenido nuevo)
    return null;
  }

  Future<void> _bootstrap() async {
    try {
      // Cargar IDs vistos desde sessionStorage
      _swipedIds = _seenStorage.load();

      final mediaType = _currentMediaType;
      final first = await _fetchNextWithRetry(excludeIds: _swipedIds, mediaType: mediaType);
      if (first != null) {
        _swipedIds.add(first.id);
        _seenStorage.add(first.id);
      }
      final second = first == null
          ? null
          : await _fetchNextWithRetry(excludeIds: _swipedIds, mediaType: mediaType);
      if (second != null) {
        _swipedIds.add(second.id);
        _seenStorage.add(second.id);
      }

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
    _seenStorage.clear();
    _swipedIds = {};
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
      final coupleId = status['coupleId'] as String?;
      final hasRoom = status['hasRoom'] as bool? ?? false;
      if (!hasRoom || coupleId == null) return;
      _ref.read(socketServiceProvider).connect(
            token: token,
            coupleId: coupleId,
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

    // Registrar localmente Y en sessionStorage
    _swipedIds.add(movie.id);
    _seenStorage.add(movie.id);

    // Avanzar a la siguiente carta
    final upcoming = state.nextMovie;
    state = state.copyWith(
      currentMovie: upcoming,
      nextMovie: null,
      noMoreMovies: upcoming == null,
    );

    // Enviar swipe al backend
    try {
      await _repository.sendSwipe(movieId: movie.id, liked: liked);
    } catch (_) {}

    // Precargar la siguiente carta con retry anti-repetición
    if (upcoming != null) {
      final mediaType = _currentMediaType;
      final preloaded = await _fetchNextWithRetry(excludeIds: _swipedIds, mediaType: mediaType);
      if (preloaded != null) {
        _swipedIds.add(preloaded.id);
        _seenStorage.add(preloaded.id);
      }
      state = state.copyWith(nextMovie: preloaded);
    }

    _isSwiping = false;
  }
}

final swipeControllerProvider = StateNotifierProvider.autoDispose<SwipeController, SwipeState>((ref) {
  return SwipeController(
    ref.watch(moviesRepositoryProvider),
    ref.watch(tokenStorageProvider),
    ref,
    ref.watch(seenMoviesStorageProvider),
  );
});
