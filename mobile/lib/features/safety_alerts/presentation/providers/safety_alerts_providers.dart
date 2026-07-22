import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/repositories/safety_alerts_repository_impl.dart';
import '../../domain/entities/safety_alert_entity.dart';
import '../../domain/repositories/safety_alerts_repository.dart';

final safetyAlertsRepositoryProvider = Provider<SafetyAlertsRepository>((ref) {
  return SafetyAlertsRepositoryImpl(ref.watch(firestoreProvider));
});

final recentSafetyAlertsProvider = StreamProvider.autoDispose<List<SafetyAlertEntity>>((ref) {
  return ref.watch(safetyAlertsRepositoryProvider).watchRecent();
});
