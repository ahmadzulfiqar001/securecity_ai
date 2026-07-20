/// Mirrors the full schema in
/// `mobile/lib/data/models/incident_model.dart` — the dashboard is a second
/// reader/writer of the same `incidents` collection.
class IncidentEntity {
  final String id;
  final String reporterId;
  final String incidentType;
  final String severity;
  final String title;
  final String description;
  final List<double> location;
  final String address;
  final String status;
  final List<String> evidenceUrls;
  final String? assignedOfficerId;
  final bool isAnonymous;
  final String? aiClassification;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  IncidentEntity({
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
    required this.isAnonymous,
    this.aiClassification,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });
}
