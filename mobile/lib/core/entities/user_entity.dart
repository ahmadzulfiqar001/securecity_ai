import 'emergency_contact_entity.dart';

/// Shared user-profile domain entity. Lives in `core/` (not inside the
/// `authentication` feature) because it's a cross-cutting concept many
/// features legitimately need to read (home greeting, profile screen,
/// incident reporterId, etc.) - keeping it here means those features
/// depend on `core/`, never on the `authentication` feature directly.
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
