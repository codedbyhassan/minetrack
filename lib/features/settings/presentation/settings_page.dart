import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Application', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.security_outlined),
                  title: Text('Secure session'),
                  subtitle: Text('Authentication is managed by Supabase Auth.'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('Backend'),
                  subtitle: Text('Supabase'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Account', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              subtitle: const Text('End the current MineTrack session'),
              onTap: () => ref.read(authControllerProvider).signOut(),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'MineTrack • Native Android Client',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
