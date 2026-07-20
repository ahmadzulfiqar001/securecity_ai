class EmergencyContactModel {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }
}
