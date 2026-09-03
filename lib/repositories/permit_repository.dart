import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/permit.dart';
import '../models/renewal.dart';

class PermitRepository {
  PermitRepository(this._client);

  final SupabaseClient _client;

  static const _permitSelect = '''
    *,
    sector:sectors(*),
    undertaking_type:undertaking_types(*)
  ''';

  Future<List<Sector>> getSectors() async {
    final rows = await _client
        .from('sectors')
        .select()
        .order('sort_order');
    return rows.map((row) => Sector.fromJson(row)).toList();
  }

  Future<List<UndertakingType>> getUndertakingTypes(String sectorId) async {
    final rows = await _client
        .from('undertaking_types')
        .select()
        .eq('sector_id', sectorId)
        .order('sort_order');
    return rows.map((row) => UndertakingType.fromJson(row)).toList();
  }

  Future<List<Permit>> getPermits({
    String? search,
    String? sectorId,
    bool? revoked,
  }) async {
    var query = _client.from('permits').select(_permitSelect);

    if (sectorId != null && sectorId.isNotEmpty) {
      query = query.eq('sector_id', sectorId);
    }
    if (revoked != null) {
      query = query.eq('revoked', revoked);
    }
    if (search != null && search.trim().isNotEmpty) {
      final term = search.trim();
      query = query.or(
        'file_number.ilike.%$term%,proponent_name.ilike.%$term%,region.ilike.%$term%,district.ilike.%$term%,town_site.ilike.%$term%',
      );
    }

    final rows = await query.order('created_at', ascending: false);
    return rows.map((row) => Permit.fromJson(row)).toList();
  }

  Future<Permit> getPermit(String id) async {
    final row = await _client
        .from('permits')
        .select(_permitSelect)
        .eq('id', id)
        .single();
    return Permit.fromJson(row);
  }

  Future<Permit> createPermit(Map<String, dynamic> data) async {
    final row = await _client
        .from('permits')
        .insert(data)
        .select(_permitSelect)
        .single();
    return Permit.fromJson(row);
  }

  Future<Permit> updatePermit(String id, Map<String, dynamic> data) async {
    final row = await _client
        .from('permits')
        .update(data)
        .eq('id', id)
        .select(_permitSelect)
        .single();
    return Permit.fromJson(row);
  }

  Future<void> deletePermit(String id) async {
    await _client.from('permits').delete().eq('id', id);
  }

  Future<List<Renewal>> getRenewals(String permitId) async {
    final rows = await _client
        .from('renewals')
        .select()
        .eq('permit_id', permitId)
        .order('renewed_at', ascending: false);
    return rows.map((row) => Renewal.fromJson(row)).toList();
  }

  Future<Renewal> createRenewal(Map<String, dynamic> data) async {
    final row = await _client
        .from('renewals')
        .insert(data)
        .select()
        .single();
    return Renewal.fromJson(row);
  }
}
