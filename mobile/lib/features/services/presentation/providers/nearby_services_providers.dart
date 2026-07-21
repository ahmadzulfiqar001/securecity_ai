import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/nearby_services_repository_impl.dart';
import '../../domain/entities/nearby_service_entity.dart';
import '../../domain/repositories/nearby_services_repository.dart';

final nearbyServicesRepositoryProvider = Provider<NearbyServicesRepository>((ref) {
  return NearbyServicesRepositoryImpl(ref.watch(firestoreProvider));
});

final nearbyServicesStreamProvider = StreamProvider.autoDispose<List<NearbyServiceEntity>>((ref) {
  return ref.watch(nearbyServicesRepositoryProvider).watchAll();
});
