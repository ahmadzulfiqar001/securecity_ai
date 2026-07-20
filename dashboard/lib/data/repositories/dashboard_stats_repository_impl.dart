import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/dashboard_stats_repository.dart';

class DashboardStatsRepositoryImpl implements DashboardStatsRepository {
  final FirebaseFirestore _firestore;

  DashboardStatsRepositoryImpl(this._firestore);

  @override
  Stream<DashboardStatsEntity> watchStats() {
    final controller = StreamController<DashboardStatsEntity>.broadcast();
    QuerySnapshot<Map<String, dynamic>>? latestSos;
    QuerySnapshot<Map<String, dynamic>>? latestIncidents;

    void emit() {
      if (latestSos == null || latestIncidents == null) return;
      controller.add(_computeStats(latestSos!, latestIncidents!));
    }

    final sosSub = _firestore
        .collection(AppConstants.colSosEvents)
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .listen((snapshot) {
      latestSos = snapshot;
      emit();
    }, onError: controller.addError);

    final incidentsSub =
        _firestore.collection(AppConstants.colIncidents).snapshots().listen((snapshot) {
      latestIncidents = snapshot;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () {
      sosSub.cancel();
      incidentsSub.cancel();
    };

    return controller.stream;
  }

  DashboardStatsEntity _computeStats(
    QuerySnapshot<Map<String, dynamic>> sosSnapshot,
    QuerySnapshot<Map<String, dynamic>> incidentsSnapshot,
  ) {
    final now = DateTime.now();
    var incidentsToday = 0;
    final byType = <String, int>{};

    for (final doc in incidentsSnapshot.docs) {
      final data = doc.data();
      final type = data['incidentType'] as String? ?? 'OTHER';
      byType[type] = (byType[type] ?? 0) + 1;

      final createdAtRaw = data['createdAt'] as String?;
      final createdAt = createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null;
      if (createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day) {
        incidentsToday++;
      }
    }

    return DashboardStatsEntity(
      activeSosCount: sosSnapshot.docs.length,
      incidentsTodayCount: incidentsToday,
      totalIncidentsCount: incidentsSnapshot.docs.length,
      incidentsByType: byType,
    );
  }
}
