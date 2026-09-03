import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/permit_providers.dart';

class RenewPermitPage extends ConsumerStatefulWidget {
  const RenewPermitPage({super.key, required this.permitId});
  final String permitId;

  @override
  ConsumerState<RenewPermitPage> createState() => _RenewPermitPageState();
}

class _RenewPermitPageState extends ConsumerState<RenewPermitPage> {
  final _formKey = GlobalKey<FormState>();
  final _monthsController = TextEditingController(text: '12');
  final _renewalFeeController = TextEditingController(text: '0');
  final _processingFeeController = TextEditingController(text: '0');
  DateTime? _effectiveDate;
  bool _saving = false;

  @override
  void dispose() {
    _monthsController.dispose();
    _renewalFeeController.dispose();
    _processingFeeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _effectiveDate ?? DateTime.now(),
    );
    if (selected != null) setState(() => _effectiveDate = selected);
  }

  DateTime _addMonths(DateTime date, int months) {
    final target = date.month - 1 + months;
    final year = date.year + target ~/ 12;
    final month = target % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day.clamp(1, lastDay));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_effectiveDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select the new effective date.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final months = int.parse(_monthsController.text.trim());
      final renewalFee = num.parse(_renewalFeeController.text.trim());
      final processingFee = num.parse(_processingFeeController.text.trim());
      final repository = ref.read(permitRepositoryProvider);
      final permit = await repository.getPermit(widget.permitId);
      final expiry = _addMonths(_effectiveDate!, months);
      String date(DateTime value) => value.toIso8601String().split('T').first;

      await repository.createRenewal({
        'permit_id': widget.permitId,
        'previous_expiry_date': permit.expiryDate == null ? null : date(permit.expiryDate!),
        'new_effective_date': date(_effectiveDate!),
        'new_validity_months': months,
        'new_expiry_date': date(expiry),
        'renewal_fee': renewalFee,
        'processing_fee': processingFee,
      });

      await repository.updatePermit(widget.permitId, {
        'effective_date': date(_effectiveDate!),
        'validity_months': months,
        'revoked': false,
      });

      ref.invalidate(permitProvider(widget.permitId));
      ref.invalidate(renewalsProvider(widget.permitId));
      ref.invalidate(permitsProvider);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Renewal failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permit = ref.watch(permitProvider(widget.permitId));
    final format = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Renew Permit')),
      body: permit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load permit: $error')),
        data: (p) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.fileNumber, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(p.proponentName),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('New effective date'),
                subtitle: Text(_effectiveDate == null ? 'Select date' : format.format(_effectiveDate!)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Validity (months)'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  return parsed == null || parsed <= 0 ? 'Enter a valid number of months' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _renewalFeeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Renewal fee'),
                validator: (value) => num.tryParse(value?.trim() ?? '') == null ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _processingFeeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Processing fee'),
                validator: (value) => num.tryParse(value?.trim() ?? '') == null ? 'Enter a valid amount' : null,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.autorenew),
                label: Text(_saving ? 'Processing...' : 'Confirm renewal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
