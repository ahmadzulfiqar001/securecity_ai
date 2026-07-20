import '../entities/map_zone_entity.dart';

abstract class MapZoneRepository {
  /// All active zones — used for both map display and geofencing.
  Stream<List<MapZoneEntity>> watchActive();
}
