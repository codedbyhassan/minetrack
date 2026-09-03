import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../permits/providers/permit_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permitsAsync = ref.watch(permitsProvider);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final warningEnd = start.add(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(onPressed: () => ref.invalidate(permitsProvider), icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
        ],
      ),
      body: permitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load alerts.\n$error', textAlign: TextAlign.center)),
        data: (permits) {
          final alerts = permits.where((permit) {
            if (permit.revoked || permit.expiryDate == null) return false;
            return !permit.expiryDate!.isAfter(warningEnd);
          }).toList()..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

          if (alerts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 52),
                    SizedBox(height: 16),
                    Text('No expiry alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('There are no active permits expiring within the next 30 days.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final permit = alerts[index];
              final expiry = permit.expiryDate!;
              final days = expiry.difference(start).inDays;
              final overdue = days < 0;
              final label = overdue ? 'Expired ${-days} days ago' : days == 0 ? 'Expires today' : 'Expires in $days days';
              return Card(
                child: ListTile(
                  leading: Icon(overdue ? Icons.error_outline : Icons.schedule_outlined),
                  title: Text(permit.fileNumber),
                  subtitle: Text('${permit.proponentName}\n$label • ${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
