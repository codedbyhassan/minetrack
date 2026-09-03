import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../permits/providers/permit_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permitsAsync = ref.watch(permitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MineTrack'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(permitsProvider.future);
        },
        child: permitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Unable to load permit data',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => ref.invalidate(permitsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
          data: (permits) {
            final total = permits.length;
            final active = permits.where((p) => !p.revoked).length;
            final revoked = permits.where((p) => p.revoked).length;
            final now = DateTime.now();
            final threshold = now.add(const Duration(days: 30));
            final expiringSoon = permits.where((p) {
              final expiry = p.expiryDate;
              return !p.revoked &&
                  expiry != null &&
                  !expiry.isBefore(DateTime(now.year, now.month, now.day)) &&
                  !expiry.isAfter(threshold);
            }).length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Permit overview',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text('Monitor registrations and permit activity.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                _StatCard(label: 'Total permits', value: '$total', icon: Icons.description_outlined),
                const SizedBox(height: 12),
                _StatCard(label: 'Active permits', value: '$active', icon: Icons.verified_outlined),
                const SizedBox(height: 12),
                _StatCard(label: 'Expiring in 30 days', value: '$expiringSoon', icon: Icons.schedule_outlined),
                const SizedBox(height: 12),
                _StatCard(label: 'Revoked permits', value: '$revoked', icon: Icons.block_outlined),
                const SizedBox(height: 28),
                Text(
                  'Quick actions',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/permits/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Register a new permit'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.push('/permits'),
                  icon: const Icon(Icons.search),
                  label: const Text('Search permit registry'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
