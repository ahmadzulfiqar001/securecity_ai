import '../../../emergency_contacts/domain/entities/emergency_contact_entity.dart';

class UserEntity {
  final String id;
  final String firebaseUid;
  final String email;
  final String phone;
  final String fullName;
  final String? profilePhotoUrl;
  final String role;
  final bool isActive;
  final bool isVerified;
  final double riskScore;
  final List<double>? location;
  final List<EmergencyContactEntity> emergencyContacts;
  final String createdAt;
  final String updatedAt;

  UserEntity({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.phone,
    required this.fullName,
    this.profilePhotoUrl,
    required this.role,
    required this.isActive,
    required this.isVerified,
    required this.riskScore,
    this.location,
    required this.emergencyContacts,
    required this.createdAt,
    required this.updatedAt,
  });
}
