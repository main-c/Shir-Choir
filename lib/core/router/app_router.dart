import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/choriste/presentation/pages/choriste_dashboard_page.dart';
import '../../features/choriste/presentation/pages/song_detail_page.dart';
import '../../features/maestro/presentation/pages/maestro_dashboard_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/choriste/presentation/pages/choir_profile_page.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/';
      
      if (!isLoggedIn && !isLoggingIn) {
        return '/';
      }
      
      if (isLoggedIn && isLoggingIn) {
        return authState.user?.role == 'maestro' ? '/maestro' : '/choriste';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/choriste',
        name: 'choriste-dashboard',
        builder: (context, state) => const ChoristeDashboardPage(),
      ),
      GoRoute(
        path: '/choriste/chant/:id',
        name: 'song-detail',
        builder: (context, state) {
          final songId = state.pathParameters['id']!;
          return SongDetailPage(songId: songId);
        },
      ),
      GoRoute(
        path: '/maestro',
        name: 'maestro-dashboard',
        builder: (context, state) => const MaestroDashboardPage(),
      ),
      GoRoute(
        path: '/choir/profile',
        name: 'choir-profile',
        builder: (context, state) => const ChoirProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/user/settings',
        name: 'user-settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
