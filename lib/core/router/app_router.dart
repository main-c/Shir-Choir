import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/choriste/presentation/pages/choriste_dashboard_page.dart';
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
      // Routes désactivées pour la release
      GoRoute(
        path: '/maestro',
        name: 'maestro-dashboard',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('En développement')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Mode Maestro',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fonctionnalité est en cours de développement\net sera disponible dans une prochaine version.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/choir/profile',
        name: 'choir-profile',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('En développement')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Profil de la Chorale',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Cette fonctionnalité est en cours de développement\net sera disponible dans une prochaine version.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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
