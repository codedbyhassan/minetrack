import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const destinations = [
    (path: '/dashboard', label: 'Home', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
    (path: '/permits', label: 'Permits', icon: Icons.description_outlined, selectedIcon: Icons.description),
    (path: '/map', label: 'Map', icon: Icons.map_outlined, selectedIcon: Icons.map),
    (path: '/notifications', label: 'Alerts', icon: Icons.notifications_none, selectedIcon: Icons.notifications),
  ];

  int _index(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = destinations.indexWhere((item) => location == item.path || location.startsWith('${item.path}/'));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _index(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) => context.go(destinations[index].path),
        destinations: [
          for (final destination in destinations)
            NavigationDestination(icon: Icon(destination.icon), selectedIcon: Icon(destination.selectedIcon), label: destination.label),
        ],
      ),
    );
  }
}
