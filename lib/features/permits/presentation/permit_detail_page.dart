import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/permit_providers.dart';

class PermitDetailPage extends ConsumerWidget {
  const PermitDetailPage({super.key, required this.permitId});
  final String permitId;

  String _date(DateTime? value) => value == null ? '—' : value.toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permit = ref.watch(permitProvider(permitId));
    final renewals = ref.watch(renewalsProvider(permitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Permit Details'), actions: [IconButton(tooltip: 'Refresh', onPressed: () { ref.invalidate(permitProvider(permitId)); ref.invalidate(renewalsProvider(permitId)); }, icon: const Icon(Icons.refresh))]),
      body: permit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48), const SizedBox(height: 12), Text('Unable to load permit: $error', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: () => ref.invalidate(permitProvider(permitId)), child: const Text('Retry'))])),
        data: (p) => ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
          Text(p.fileNumber, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(p.revoked ? 'REVOKED' : 'ACTIVE', style: TextStyle(fontWeight: FontWeight.w700, color: p.revoked ? Colors.red : Colors.green)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => context.push('/permits/${p.id}/renew'), icon: const Icon(Icons.autorenew), label: const Text('Renew permit')),
          const SizedBox(height: 12),
          _group(context, 'Proponent', [_row('Proponent', p.proponentName), _row('Contact person', p.contactPerson), _row('Phone', p.contactPhone)]),
          _group(context, 'Location', [_row('Region', p.region), _row('District', p.district), _row('Town / site', p.townSite), _row('Latitude', p.latitude?.toString()), _row('Longitude', p.longitude?.toString())]),
          _group(context, 'Classification', [_row('Sector', p.sector?.name), _row('Undertaking', p.undertakingType?.name), _row('Capacity', p.capacity == null ? null : '${p.capacity} ${p.capacityUnit ?? ''}'.trim())]),
          _group(context, 'Validity', [_row('Effective date', _date(p.effectiveDate)), _row('Validity', p.validityMonths == null ? null : '${p.validityMonths} months'), _row('Expiry date', _date(p.expiryDate))]),
          _group(context, 'Fees', [_row('Permit fee', p.permitFee.toStringAsFixed(2)), _row('Processing fee', p.processingFee.toStringAsFixed(2)), _row('Total cost', p.totalCost.toStringAsFixed(2))]),
          if (p.revoked) const Card(child: ListTile(leading: Icon(Icons.warning_amber_rounded), title: Text('Permit revoked'), subtitle: Text('This permit is marked as revoked.'))),
          const SizedBox(height: 8),
          Text('Renewal history', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          renewals.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (error, _) => Card(child: ListTile(leading: const Icon(Icons.error_outline), title: const Text('Unable to load renewal history'), subtitle: Text('$error'), trailing: IconButton(onPressed: () => ref.invalidate(renewalsProvider(permitId)), icon: const Icon(Icons.refresh)))),
            data: (items) => items.isEmpty ? const Card(child: ListTile(leading: Icon(Icons.history_outlined), title: Text('No renewals recorded'))) : Column(children: items.map((r) => Card(child: ListTile(title: Text('${_date(r.newEffectiveDate)} → ${_date(r.newExpiryDate)}'), subtitle: Text('${r.newValidityMonths} months • Total ${r.totalCost.toStringAsFixed(2)}')))).toList()),
          ),
        ]),
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> children) => Card(margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 10), ...children])));

  Widget _row(String label, String? value) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 125, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))), Expanded(child: Text(value?.isNotEmpty == true ? value! : '—'))]));
}
