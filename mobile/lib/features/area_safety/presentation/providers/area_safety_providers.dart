import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/area_safety_repository_impl.dart';
import '../../domain/entities/area_safety_entity.dart';
import '../../domain/repositories/area_safety_repository.dart';

final areaSafetyRepositoryProvider = Provider<AreaSafetyRepository>((ref) {
  return AreaSafetyRepositoryImpl(ref.watch(firestoreProvider));
});

final areaSafetyStreamProvider = StreamProvider.autoDispose<List<AreaSafetyEntity>>((ref) {
  return ref.watch(areaSafetyRepositoryProvider).watchAll();
});
