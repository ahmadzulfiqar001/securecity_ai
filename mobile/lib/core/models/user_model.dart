import 'emergency_contact_model.dart';

/// Shared user-profile data model (Firestore JSON mapping). Lives in
/// `core/` alongside [UserEntity] for the same reason - both the
/// `authentication` and `emergency_contacts` features need it, and
/// features should depend on `core/`, not on each other.
class UserModel {
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
  final List<double>? location; // [lng, lat]
  final List<EmergencyContactModel> emergencyContacts;
  final String createdAt;
  final String updatedAt;

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      firebaseUid: json['firebaseUid'] as String? ?? json['firebase_uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String? ?? json['profile_photo_url'] as String?,
      role: json['role'] as String? ?? 'CITIZEN',
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      riskScore: (json['riskScore'] as num? ?? json['risk_score'] as num? ?? 0.0).toDouble(),
      location: (json['location'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>? ?? json['emergency_contacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContactModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role,
      'isActive': isActive,
      'isVerified': isVerified,
      'riskScore': riskScore,
      'location': location,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
