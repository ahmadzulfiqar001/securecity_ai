import '../entities/nearby_service_entity.dart';

abstract class NearbyServicesRepository {
  Stream<List<NearbyServiceEntity>> watchAll();
}
