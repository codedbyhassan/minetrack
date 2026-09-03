import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MineTrack'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline), tooltip: 'Profile'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Permit overview', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Monitor registrations and permit activity.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          const _StatCard(label: 'Total permits', value: '—', icon: Icons.description_outlined),
          const SizedBox(height: 12),
          const _StatCard(label: 'Active permits', value: '—', icon: Icons.verified_outlined),
          const SizedBox(height: 12),
          const _StatCard(label: 'Pending review', value: '—', icon: Icons.pending_actions_outlined),
          const SizedBox(height: 28),
          Text('Quick actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Register a new permit')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.search), label: const Text('Search permit registry')),
        ],
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
        trailing: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
