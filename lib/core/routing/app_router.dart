import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/permits/presentation/new_permit_page.dart';
import '../../features/permits/presentation/permit_detail_page.dart';
import '../../features/permits/presentation/permit_registry_page.dart';
import '../../features/permits/presentation/renew_permit_page.dart';
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
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        ShellRoute(
          builder: (_, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
            GoRoute(path: '/permits', builder: (_, __) => const PermitRegistryPage()),
            GoRoute(path: '/permits/new', builder: (_, __) => const NewPermitPage()),
            GoRoute(
              path: '/permits/:id',
              builder: (_, state) => PermitDetailPage(permitId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/permits/:id/renew',
              builder: (_, state) => RenewPermitPage(permitId: state.pathParameters['id']!),
            ),
            GoRoute(path: '/map', builder: (_, __) => const _PlaceholderPage(title: 'Geospatial View')),
            GoRoute(path: '/notifications', builder: (_, __) => const _PlaceholderPage(title: 'Notifications')),
            GoRoute(path: '/profile', builder: (_, __) => const _PlaceholderPage(title: 'Profile')),
            GoRoute(path: '/settings', builder: (_, __) => const _PlaceholderPage(title: 'Settings')),
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}
