class SosEventModel {
  final String? id;
  final String userId;
  final double latitude;
  final double longitude;
  final String message;
  final String status;
  final String createdAt;

  SosEventModel({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'message': message,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
