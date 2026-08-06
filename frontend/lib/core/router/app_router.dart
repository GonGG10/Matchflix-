import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/rooms/presentation/room_code_screen.dart';
import '../../features/rooms/presentation/join_screen.dart';
import '../../features/categories/presentation/category_selection_screen.dart';
import '../../features/swipe/presentation/swipe_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/filters/presentation/filters_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/room/code', builder: (context, state) => const RoomCodeScreen()),
      GoRoute(path: '/room/join', builder: (context, state) => const JoinScreen()),
      GoRoute(path: '/categories', builder: (context, state) => const CategorySelectionScreen()),
      GoRoute(path: '/swipe', builder: (context, state) => const SwipeScreen()),
      GoRoute(path: '/matches', builder: (context, state) => const MatchesScreen()),
      GoRoute(path: '/filters', builder: (context, state) => const FiltersScreen()),
    ],
  );
});
