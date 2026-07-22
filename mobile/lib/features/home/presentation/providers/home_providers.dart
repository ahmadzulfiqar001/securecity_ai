import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/safety_alert_entity.dart';
import '../../domain/entities/safety_score_entity.dart';
import '../../domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl();
});

final safetyScoreProvider = Provider<SafetyScoreEntity>((ref) {
  return ref.watch(homeRepositoryProvider).getCurrentZoneSafetyScore();
});

final recentAlertsProvider = Provider<List<SafetyAlertEntity>>((ref) {
  return ref.watch(homeRepositoryProvider).getRecentAlerts();
});
