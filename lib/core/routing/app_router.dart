import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final routes = <RouteBase>[
    GoRoute(
      path: '/',
      redirect: (_, __) => '/dashboard',
    ),
    GoRoute(
      path: '/dashboard',
      builder: (_, __) => const _PlaceholderPage(title: 'Dashboard'),
    ),
    GoRoute(
      path: '/permits',
      builder: (_, __) => const _PlaceholderPage(title: 'Permit Registry'),
    ),
    GoRoute(
      path: '/permits/new',
      builder: (_, __) => const _PlaceholderPage(title: 'New Permit Registration'),
    ),
    GoRoute(
      path: '/map',
      builder: (_, __) => const _PlaceholderPage(title: 'Geospatial View'),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const _PlaceholderPage(title: 'Notifications'),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const _PlaceholderPage(title: 'Profile'),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const _PlaceholderPage(title: 'Settings'),
    ),
  ];
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
