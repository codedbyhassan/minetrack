import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/permit_providers.dart';

class PermitRegistryPage extends ConsumerWidget {
  const PermitRegistryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permits = ref.watch(permitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permit Registry'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(permitsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/permits/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Permit'),
      ),
      body: permits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('Unable to load permits: $error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(permitsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No permits registered yet.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(permitsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final permit = items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      permit.fileNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${permit.proponentName}\n${permit.region}${permit.district == null ? '' : ' • ${permit.district}'}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/permits/${permit.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
