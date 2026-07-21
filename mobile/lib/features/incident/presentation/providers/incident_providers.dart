import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/incident_repository_impl.dart';
import '../../domain/repositories/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepositoryImpl(ref.watch(firestoreProvider));
});
