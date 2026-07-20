/// A nearby emergency/civic service (police station, hospital, fire
/// station, shelter, or pharmacy). [distanceMeters] is computed client-side
/// from the user's current position, not stored in Firestore.
class NearbyServiceEntity {
  final String id;
  final String name;
  final String type;
  final String? phone;
  final String address;
  final double latitude;
  final double longitude;
  final double? distanceMeters;

  NearbyServiceEntity({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  NearbyServiceEntity copyWithDistance(double meters) {
    return NearbyServiceEntity(
      id: id,
      name: name,
      type: type,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: meters,
    );
  }
}

/// Service type constants matching the `type` field stored in Firestore.
abstract final class NearbyServiceType {
  static const String police = 'police';
  static const String hospital = 'hospital';
  static const String fireStation = 'fire_station';
  static const String shelter = 'shelter';
  static const String pharmacy = 'pharmacy';

  static const List<String> all = [police, hospital, fireStation, shelter, pharmacy];

  static String label(String type) => switch (type) {
        police => 'Police',
        hospital => 'Hospital',
        fireStation => 'Fire Station',
        shelter => 'Shelter',
        pharmacy => 'Pharmacy',
        _ => 'Service',
      };
}
