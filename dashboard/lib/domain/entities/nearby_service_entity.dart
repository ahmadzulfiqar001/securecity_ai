/// A registered civic service location (police station, hospital, fire
/// station, shelter, pharmacy) — same `nearby_services` Firestore
/// collection the mobile app's Nearby Services screen already reads.
class NearbyServiceEntity {
  final String id;
  final String name;
  final String type;
  final String? phone;
  final String address;
  final double latitude;
  final double longitude;

  NearbyServiceEntity({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

abstract final class NearbyServiceType {
  static const String police = 'police';
  static const String hospital = 'hospital';
  static const String fireStation = 'fire_station';
  static const String shelter = 'shelter';
  static const String pharmacy = 'pharmacy';

  static String label(String type) => switch (type) {
        police => 'Police',
        hospital => 'Hospital',
        fireStation => 'Fire Station',
        shelter => 'Shelter',
        pharmacy => 'Pharmacy',
        _ => 'Service',
      };
}
