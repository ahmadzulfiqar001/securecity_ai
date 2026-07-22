/// A citizen-submitted incident report, as captured by the report form.
/// Server/dashboard-assigned fields (Firestore doc id, assigned officer,
/// timeline, AI classification, resolvedAt) aren't part of submission and
/// are added later by the triage pipeline - see `IncidentModel` for the
/// full record shape once those are populated.
class IncidentEntity {
  /// Firestore document id. Absent when constructing a new report to
  /// submit (see [IncidentRepository.newIncidentId]); populated when
  /// reading reports back (see [IncidentRepository.watchMyReports]).
  final String? id;
  final String reporterId;
  final String title;
  final String description;
  final String incidentType;
  final String severity;
  final bool isAnonymous;
  final String status;
  final List<double> location; // [lng, lat]
  final String address;
  final List<String> evidenceUrls;
  final String createdAt;
  final String updatedAt;

  IncidentEntity({
    this.id,
    required this.reporterId,
    required this.title,
    required this.description,
    required this.incidentType,
    required this.severity,
    required this.isAnonymous,
    required this.status,
    required this.location,
    required this.address,
    required this.evidenceUrls,
    required this.createdAt,
    required this.updatedAt,
  });
}
