import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/permit_providers.dart';

class PermitDetailPage extends ConsumerWidget {
  const PermitDetailPage({super.key, required this.permitId});

  final String permitId;

  String _date(DateTime? value) {
    if (value == null) return '—';
    return value.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permitAsync = ref.watch(permitProvider(permitId));
    final renewalsAsync = ref.watch(renewalsProvider(permitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permit Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(permitProvider(permitId));
              ref.invalidate(renewalsProvider(permitId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: permitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Unable to load permit: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(permitProvider(permitId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (permit) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              permit.fileNumber,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              permit.revoked ? 'REVOKED' : 'ACTIVE',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: permit.revoked ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/permits/${permit.id}/renew'),
              icon: const Icon(Icons.autorenew),
              label: const Text('Renew permit'),
            ),
            const SizedBox(height: 12),
            _group(
              context,
              'Proponent',
              [
                _row('Proponent', permit.proponentName),
                _row('Contact person', permit.contactPerson),
                _row('Phone', permit.contactPhone),
              ],
            ),
            _group(
              context,
              'Location',
              [
                _row('Region', permit.region),
                _row('District', permit.district),
                _row('Town / site', permit.townSite),
                _row('Latitude', permit.latitude?.toString()),
                _row('Longitude', permit.longitude?.toString()),
              ],
            ),
            _group(
              context,
              'Classification',
              [
                _row('Sector', permit.sector?.name),
                _row('Undertaking', permit.undertakingType?.name),
                _row(
                  'Capacity',
                  permit.capacity == null
                      ? null
                      : '${permit.capacity} ${permit.capacityUnit ?? ''}'.trim(),
                ),
              ],
            ),
            _group(
              context,
              'Validity',
              [
                _row('Effective date', _date(permit.effectiveDate)),
                _row(
                  'Validity',
                  permit.validityMonths == null
                      ? null
                      : '${permit.validityMonths} months',
                ),
                _row('Expiry date', _date(permit.expiryDate)),
              ],
            ),
            _group(
              context,
              'Fees',
              [
                _row('Permit fee', permit.permitFee.toStringAsFixed(2)),
                _row(
                  'Processing fee',
                  permit.processingFee.toStringAsFixed(2),
                ),
                _row('Total cost', permit.totalCost.toStringAsFixed(2)),
              ],
            ),
            if (permit.revoked)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded),
                  title: Text('Permit revoked'),
                  subtitle: Text('This permit is marked as revoked.'),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Renewal history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            renewalsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Card(
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Unable to load renewal history'),
                  subtitle: Text('$error'),
                  trailing: IconButton(
                    onPressed: () =>
                        ref.invalidate(renewalsProvider(permitId)),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ),
              data: (renewals) {
                if (renewals.isEmpty) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.history_outlined),
                      title: Text('No renewals recorded'),
                    ),
                  );
                }

                return Column(
                  children: renewals
                      .map(
                        (renewal) => Card(
                          child: ListTile(
                            title: Text(
                              '${_date(renewal.newEffectiveDate)} → '
                              '${_date(renewal.newExpiryDate)}',
                            ),
                            subtitle: Text(
                              '${renewal.newValidityMonths} months • '
                              'Total ${renewal.totalCost.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value?.isNotEmpty == true ? value! : '—'),
          ),
        ],
      ),
    );
  }
}
