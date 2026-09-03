import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/permit_providers.dart';

class NewPermitPage extends ConsumerStatefulWidget {
  const NewPermitPage({super.key});
  @override
  ConsumerState<NewPermitPage> createState() => _NewPermitPageState();
}

class _NewPermitPageState extends ConsumerState<NewPermitPage> {
  final formKey = GlobalKey<FormState>();
  final fileNumber = TextEditingController(), proponent = TextEditingController(), contactPerson = TextEditingController(), contactPhone = TextEditingController(), region = TextEditingController(), district = TextEditingController(), townSite = TextEditingController(), capacity = TextEditingController(), capacityUnit = TextEditingController(), validityMonths = TextEditingController(), permitFee = TextEditingController(text: '0'), processingFee = TextEditingController(text: '0');
  String? sectorId, undertakingTypeId;
  DateTime? effectiveDate;
  bool saving = false;

  @override
  void dispose() { for (final c in [fileNumber, proponent, contactPerson, contactPhone, region, district, townSite, capacity, capacityUnit, validityMonths, permitFee, processingFee]) { c.dispose(); } super.dispose(); }

  Future<void> pickDate() async {
    final date = await showDatePicker(context: context, initialDate: effectiveDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date != null) setState(() => effectiveDate = date);
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || sectorId == null || undertakingTypeId == null || effectiveDate == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all required fields.'))); return; }
    setState(() => saving = true);
    try {
      final permit = await ref.read(permitRepositoryProvider).createPermit({
        'file_number': fileNumber.text.trim(), 'proponent_name': proponent.text.trim(),
        'contact_person': contactPerson.text.trim().isEmpty ? null : contactPerson.text.trim(), 'contact_phone': contactPhone.text.trim().isEmpty ? null : contactPhone.text.trim(),
        'region': region.text.trim(), 'district': district.text.trim().isEmpty ? null : district.text.trim(), 'town_site': townSite.text.trim().isEmpty ? null : townSite.text.trim(),
        'sector_id': sectorId, 'undertaking_type_id': undertakingTypeId, 'capacity': double.tryParse(capacity.text.trim()), 'capacity_unit': capacityUnit.text.trim().isEmpty ? null : capacityUnit.text.trim(),
        'effective_date': effectiveDate!.toIso8601String().split('T').first, 'validity_months': int.tryParse(validityMonths.text.trim()), 'permit_fee': double.tryParse(permitFee.text.trim()) ?? 0, 'processing_fee': double.tryParse(processingFee.text.trim()) ?? 0,
      });
      ref.invalidate(permitsProvider);
      if (mounted) context.pushReplacement('/permits/${permit.id}');
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create permit: $e'))); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final sectors = ref.watch(sectorsProvider);
    final types = sectorId == null ? const AsyncValue<List<dynamic>>.data([]) : ref.watch(undertakingTypesProvider(sectorId!));
    return Scaffold(appBar: AppBar(title: const Text('New Permit')), body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      section('Permit information'), field(fileNumber, 'File number', required: true), field(proponent, 'Proponent name', required: true), field(contactPerson, 'Contact person'), field(contactPhone, 'Contact phone', keyboardType: TextInputType.phone),
      section('Location'), field(region, 'Region', required: true), field(district, 'District'), field(townSite, 'Town / site'), section('Classification'),
      sectors.when(loading: () => const LinearProgressIndicator(), error: (e, _) => Text('Unable to load sectors: $e'), data: (items) => DropdownButtonFormField<String>(initialValue: sectorId, decoration: const InputDecoration(labelText: 'Sector', border: OutlineInputBorder()), items: items.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name))).toList(), onChanged: (v) => setState(() { sectorId = v; undertakingTypeId = null; }), validator: (v) => v == null ? 'Select a sector' : null)),
      const SizedBox(height: 14), types.when(loading: () => const LinearProgressIndicator(), error: (e, _) => Text('Unable to load undertaking types: $e'), data: (items) => DropdownButtonFormField<String>(initialValue: undertakingTypeId, decoration: const InputDecoration(labelText: 'Undertaking type', border: OutlineInputBorder()), items: items.map<DropdownMenuItem<String>>((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.name))).toList(), onChanged: sectorId == null ? null : (v) => setState(() => undertakingTypeId = v), validator: (v) => v == null ? 'Select an undertaking type' : null)),
      section('Capacity & validity'), Row(children: [Expanded(child: field(capacity, 'Capacity', keyboardType: TextInputType.number)), const SizedBox(width: 12), Expanded(child: field(capacityUnit, 'Unit'))]), field(validityMonths, 'Validity (months)', keyboardType: TextInputType.number), ListTile(contentPadding: EdgeInsets.zero, title: const Text('Effective date'), subtitle: Text(effectiveDate == null ? 'Select date' : effectiveDate!.toIso8601String().split('T').first), trailing: const Icon(Icons.calendar_today_outlined), onTap: pickDate),
      section('Fees'), Row(children: [Expanded(child: field(permitFee, 'Permit fee', keyboardType: TextInputType.number)), const SizedBox(width: 12), Expanded(child: field(processingFee, 'Processing fee', keyboardType: TextInputType.number))]), const SizedBox(height: 24),
      FilledButton.icon(onPressed: saving ? null : save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(saving ? 'Saving…' : 'Register Permit')),
    ])));
  }

  Widget section(String title) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 12), child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)));
  Widget field(TextEditingController c, String label, {bool required = false, TextInputType? keyboardType}) => Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(controller: c, keyboardType: keyboardType, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), validator: required ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null : null));
}
