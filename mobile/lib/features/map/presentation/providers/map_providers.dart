import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/geofence_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/map_zone_repository_impl.dart';
import '../../data/repositories/predictions_repository_impl.dart';
import '../../domain/entities/map_zone_entity.dart';
import '../../domain/repositories/map_zone_repository.dart';
import '../../domain/repositories/predictions_repository.dart';

final mapZoneRepositoryProvider = Provider<MapZoneRepository>((ref) {
  return MapZoneRepositoryImpl(ref.watch(firestoreProvider));
});

final activeZonesStreamProvider = StreamProvider.autoDispose<List<MapZoneEntity>>((ref) {
  return ref.watch(mapZoneRepositoryProvider).watchActive();
});

final predictionsRepositoryProvider = Provider<PredictionsRepository>((ref) {
  return PredictionsRepositoryImpl(ref.watch(apiClientProvider));
});

final geofenceServiceProvider = Provider<GeofenceService>((ref) => GeofenceService());

/// Starts client-side geofence monitoring: subscribes to the active
/// `map_zones` stream and the device's location stream, and fires a local
/// notification (via NotificationService) on zone enter/exit. Server-side
/// geofencing (background/killed-app alerts via a Cloud Function) was
/// explicitly scoped out — this only runs while the app is open.
class GeofenceMonitor {
  GeofenceMonitor({
    required MapZoneRepository zoneRepository,
    required LocationService locationService,
    required NotificationService notificationService,
    required GeofenceService geofenceService,
  })  : _zoneRepository = zoneRepository,
        _locationService = locationService,
        _notificationService = notificationService,
        _geofenceService = geofenceService;

  final MapZoneRepository _zoneRepository;
  final LocationService _locationService;
  final NotificationService _notificationService;
  final GeofenceService _geofenceService;

  List<MapZoneEntity> _activeZones = [];
  StreamSubscription<List<MapZoneEntity>>? _zoneSubscription;
  StreamSubscription<Position>? _positionSubscription;

  void start() {
    _zoneSubscription = _zoneRepository.watchActive().listen((zones) => _activeZones = zones);

    final positionStream = _locationService.startLocationStream();
    _positionSubscription = positionStream?.listen(_onPosition);
  }

  void _onPosition(Position position) {
    final result = _geofenceService.update((position.latitude, position.longitude), _activeZones);

    for (final zone in result.entered) {
      _notificationService.showGeofenceAlert(
        id: zone.id.hashCode,
        title: 'Entering ${MapZoneType.label(zone.type)}',
        body: zone.name,
      );
    }
    for (final zone in result.exited) {
      _notificationService.showGeofenceAlert(
        id: zone.id.hashCode ^ 0x5EC0DE,
        title: 'Leaving ${MapZoneType.label(zone.type)}',
        body: zone.name,
      );
    }
  }

  void dispose() {
    _zoneSubscription?.cancel();
    _positionSubscription?.cancel();
  }
}

final geofenceMonitorProvider = Provider<GeofenceMonitor>((ref) {
  final monitor = GeofenceMonitor(
    zoneRepository: ref.watch(mapZoneRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    geofenceService: ref.watch(geofenceServiceProvider),
  );
  monitor.start();
  ref.onDispose(monitor.dispose);
  return monitor;
});
