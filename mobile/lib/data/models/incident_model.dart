class IncidentModel {
  final String id;
  final String reporterId;
  final String incidentType;
  final String severity;
  final String title;
  final String description;
  final List<double> location; // [lng, lat]
  final String address;
  final String status;
  final List<String> evidenceUrls;
  final String? assignedOfficerId;
  final List<Map<String, dynamic>> timeline;
  final bool isAnonymous;
  final String? aiClassification;
  final String createdAt;
  final String updatedAt;
  final String? resolvedAt;

  IncidentModel({
    required this.id,
    required this.reporterId,
    required this.incidentType,
    required this.severity,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.status,
    required this.evidenceUrls,
    this.assignedOfficerId,
    required this.timeline,
    required this.isAnonymous,
    this.aiClassification,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? json['reporter_id'] as String? ?? '',
      incidentType: json['incidentType'] as String? ?? json['incident_type'] as String? ?? 'OTHER',
      severity: json['severity'] as String? ?? 'MEDIUM',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: (json['location'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'REPORTED',
      evidenceUrls: (json['evidenceUrls'] as List<dynamic>? ?? json['evidence_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      assignedOfficerId: json['assignedOfficerId'] as String? ?? json['assigned_officer_id'] as String?,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      isAnonymous: json['isAnonymous'] as bool? ?? json['is_anonymous'] as bool? ?? false,
      aiClassification: json['aiClassification'] as String? ?? json['ai_classification'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
      resolvedAt: json['resolvedAt'] as String? ?? json['resolved_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'incidentType': incidentType,
      'severity': severity,
      'title': title,
      'description': description,
      'location': location,
      'address': address,
      'status': status,
      'evidenceUrls': evidenceUrls,
      'assignedOfficerId': assignedOfficerId,
      'timeline': timeline,
      'isAnonymous': isAnonymous,
      'aiClassification': aiClassification,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'resolvedAt': resolvedAt,
    };
  }
}
