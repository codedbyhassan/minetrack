import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/permit.dart';
import '../../../models/renewal.dart';
import '../../../repositories/permit_repository.dart';

final permitRepositoryProvider = Provider<PermitRepository>((ref) {
  return PermitRepository(Supabase.instance.client);
});

final sectorsProvider = FutureProvider<List<Sector>>((ref) {
  return ref.watch(permitRepositoryProvider).getSectors();
});

final undertakingTypesProvider = FutureProvider.family<List<UndertakingType>, String>(
  (ref, sectorId) {
    return ref.watch(permitRepositoryProvider).getUndertakingTypes(sectorId);
  },
);

final permitsProvider = FutureProvider<List<Permit>>((ref) {
  return ref.watch(permitRepositoryProvider).getPermits();
});

final permitProvider = FutureProvider.family<Permit, String>((ref, id) {
  return ref.watch(permitRepositoryProvider).getPermit(id);
});

final renewalsProvider = FutureProvider.family<List<Renewal>, String>((ref, permitId) {
  return ref.watch(permitRepositoryProvider).getRenewals(permitId);
});
