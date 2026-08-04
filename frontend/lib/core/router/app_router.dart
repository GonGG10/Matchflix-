import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/couple/presentation/create_couple_screen.dart';
import '../../features/couple/presentation/join_couple_screen.dart';
import '../../features/categories/presentation/category_selection_screen.dart';
import '../../features/swipe/presentation/swipe_screen.dart';
import '../../features/matches/presentation/matches_screen.dart';
import '../../features/filters/presentation/filters_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/couple/welcome', builder: (context, state) => const CoupleWelcomeScreen()),
      GoRoute(path: '/couple/create/code', builder: (context, state) => const CoupleCodeScreen()),
      GoRoute(path: '/couple/join', builder: (context, state) => const JoinCoupleScreen()),
      GoRoute(path: '/categories', builder: (context, state) => const CategorySelectionScreen()),
      GoRoute(path: '/swipe', builder: (context, state) => const SwipeScreen()),
      GoRoute(path: '/matches', builder: (context, state) => const MatchesScreen()),
      GoRoute(path: '/filters', builder: (context, state) => const FiltersScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    ],
  );
});
