import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/map/presentation/permit_map_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/permits/presentation/new_permit_page.dart';
import '../../features/permits/presentation/permit_detail_page.dart';
import '../../features/permits/presentation/permit_registry_page.dart';
import '../../features/permits/presentation/renew_permit_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../services/supabase_service.dart';
import '../shell/app_shell.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: GoRouterRefreshStream(
        SupabaseService.client.auth.onAuthStateChange,
      ),
      redirect: (context, state) {
        final signedIn = SupabaseService.client.auth.currentSession != null;
        final isLogin = state.matchedLocation == '/login';
        if (!signedIn && !isLogin) return '/login';
        if (signedIn && isLogin) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => const LoginPage(),
        ),
        ShellRoute(
          builder: (_, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, _) => const DashboardPage(),
            ),
            GoRoute(
              path: '/permits',
              builder: (_, _) => const PermitRegistryPage(),
            ),
            GoRoute(
              path: '/permits/new',
              builder: (_, _) => const NewPermitPage(),
            ),
            GoRoute(
              path: '/permits/:id',
              builder: (_, state) => PermitDetailPage(
                permitId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/permits/:id/renew',
              builder: (_, state) => RenewPermitPage(
                permitId: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: '/map',
              builder: (_, _) => const PermitMapPage(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (_, _) => const NotificationsPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfilePage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsPage(),
            ),
          ],
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
