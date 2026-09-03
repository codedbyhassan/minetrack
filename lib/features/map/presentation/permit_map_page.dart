import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../permits/providers/permit_providers.dart';

class PermitMapPage extends ConsumerWidget {
  const PermitMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permitsAsync = ref.watch(permitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Permit locations')),
      body: permitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load permit locations.\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (permits) {
          final located = permits.where((permit) => permit.latitude != null && permit.longitude != null).toList();
          if (located.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined, size: 52),
                    SizedBox(height: 16),
                    Text('No permit locations available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text('Permits with latitude and longitude will appear here.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: located.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final permit = located[index];
              final lat = permit.latitude!;
              final lng = permit.longitude!;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
                  title: Text(permit.fileNumber),
                  subtitle: Text('${permit.proponentName}\n${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Open in Maps',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Maps')));
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
