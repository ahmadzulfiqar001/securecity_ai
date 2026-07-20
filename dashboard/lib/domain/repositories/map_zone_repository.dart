import '../../core/errors/result.dart';
import '../entities/map_zone_entity.dart';

abstract class MapZoneRepository {
  Stream<List<MapZoneEntity>> watchAll();

  Future<Result<void>> createZone(MapZoneEntity zone);

  Future<Result<void>> updateZone(MapZoneEntity zone);

  Future<Result<void>> deleteZone(String zoneId);
}
