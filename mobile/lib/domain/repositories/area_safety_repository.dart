import '../entities/area_safety_entity.dart';

abstract class AreaSafetyRepository {
  Stream<List<AreaSafetyEntity>> watchAll();
}
