/// One grid cell of the AI-generated crime density heatmap
/// (`GET /predict/heatmap` on `ai_engine` — see `heatmap_service.py`).
class HeatmapCellEntity {
  final double lat;
  final double lng;
  final double density;
  final double intensity;
  final String riskLevel; // LOW | MEDIUM | HIGH | CRITICAL

  HeatmapCellEntity({
    required this.lat,
    required this.lng,
    required this.density,
    required this.intensity,
    required this.riskLevel,
  });
}

class HeatmapEntity {
  final List<HeatmapCellEntity> cells;

  HeatmapEntity(this.cells);

  factory HeatmapEntity.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as List<dynamic>? ?? [];
    final cells = features.map((raw) {
      final feature = raw as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
      final coordinates = (geometry['coordinates'] as List<dynamic>? ?? [0.0, 0.0])
          .map((e) => (e as num).toDouble())
          .toList();
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};

      return HeatmapCellEntity(
        lng: coordinates.isNotEmpty ? coordinates[0] : 0.0,
        lat: coordinates.length > 1 ? coordinates[1] : 0.0,
        density: (properties['density'] as num?)?.toDouble() ?? 0.0,
        intensity: (properties['intensity'] as num?)?.toDouble() ?? 0.0,
        riskLevel: properties['risk_level'] as String? ?? 'LOW',
      );
    }).toList();

    return HeatmapEntity(cells);
  }
}
