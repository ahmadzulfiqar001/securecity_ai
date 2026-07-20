import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/nearby_services_repository_impl.dart';
import '../../data/repositories/predictions_repository_impl.dart';
import '../../domain/entities/nearby_service_entity.dart';
import '../../domain/entities/safety_score_entity.dart';
import '../../domain/repositories/nearby_services_repository.dart';
import '../../domain/repositories/predictions_repository.dart';
import '../emergency_queue/emergency_queue_screen.dart' show emergencyQueueStreamProvider;
import '../widgets/glass_card.dart';
import '../zone_manager/zone_manager_screen.dart' show mapZonesStreamProvider, zoneColor;

final nearbyServicesRepositoryProvider = Provider<NearbyServicesRepository>((ref) {
  return NearbyServicesRepositoryImpl(ref.watch(firestoreProvider));
});

final dashboardNearbyServicesStreamProvider = StreamProvider.autoDispose<List<NearbyServiceEntity>>((ref) {
  return ref.watch(nearbyServicesRepositoryProvider).watchAll();
});

final predictionsRepositoryProvider = Provider<PredictionsRepository>((ref) {
  return PredictionsRepositoryImpl(ref.watch(aiEngineDioProvider));
});

Color riskColor(String riskLevel) => switch (riskLevel) {
      'CRITICAL' => AppColors.emergencyRed,
      'HIGH' => Colors.deepOrange,
      'MEDIUM' => AppColors.warningAmber,
      _ => AppColors.successGreen,
    };

class InteractiveMapScreen extends ConsumerStatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  bool _showHeatmap = true;
  bool _showZones = true;
  bool _showServices = true;
  bool _showSos = true;

  List<CircleMarker> _heatmapCircles = [];
  bool _loadingHeatmap = false;
  SafetyScoreEntity? _inspectedScore;
  bool _loadingScore = false;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    setState(() => _loadingHeatmap = true);
    final result = await ref.read(predictionsRepositoryProvider).getCrimeHeatmap(
          minLat: AppConstants.mapDefaultLatitude - 0.08,
          maxLat: AppConstants.mapDefaultLatitude + 0.08,
          minLon: AppConstants.mapDefaultLongitude - 0.08,
          maxLon: AppConstants.mapDefaultLongitude + 0.08,
        );
    if (!mounted) return;
    setState(() {
      _loadingHeatmap = false;
      if (result case Success(value: final heatmap)) {
        _heatmapCircles = heatmap.cells
            .map((cell) => CircleMarker(
                  point: ll.LatLng(cell.lat, cell.lng),
                  radius: 90,
                  useRadiusInMeter: true,
                  color: riskColor(cell.riskLevel).withValues(alpha: 0.3),
                  borderColor: riskColor(cell.riskLevel),
                  borderStrokeWidth: 1,
                ))
            .toList();
      }
    });
  }

  Future<void> _inspectPoint(ll.LatLng point) async {
    setState(() {
      _loadingScore = true;
      _inspectedScore = null;
    });
    // No real per-point zone_id mapping exists client-side yet — a synthetic
    // id keeps the call honest about what it's scoring (this exact tap),
    // rather than pretending it resolved to a real administrative zone.
    final zoneId = 'tap_${point.latitude.toStringAsFixed(3)}_${point.longitude.toStringAsFixed(3)}';
    final result = await ref.read(predictionsRepositoryProvider).getSafetyScore(zoneId: zoneId);
    if (!mounted) return;
    setState(() {
      _loadingScore = false;
      if (result case Success(value: final score)) _inspectedScore = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(mapZonesStreamProvider);
    final servicesAsync = ref.watch(dashboardNearbyServicesStreamProvider);
    final sosAsync = ref.watch(emergencyQueueStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Interactive Map',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/map/zones'),
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Manage Zones'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Crime heatmap, authority-drawn zones, police/hospital locations, and active SOS alerts.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Crime Heatmap'),
              selected: _showHeatmap,
              onSelected: (v) => setState(() => _showHeatmap = v),
            ),
            FilterChip(
              label: const Text('Zones'),
              selected: _showZones,
              onSelected: (v) => setState(() => _showZones = v),
            ),
            FilterChip(
              label: const Text('Police / Hospitals'),
              selected: _showServices,
              onSelected: (v) => setState(() => _showServices = v),
            ),
            FilterChip(
              label: const Text('Active SOS'),
              selected: _showSos,
              onSelected: (v) => setState(() => _showSos = v),
            ),
            if (_loadingHeatmap) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: ll.LatLng(AppConstants.mapDefaultLatitude, AppConstants.mapDefaultLongitude),
                    initialZoom: AppConstants.mapDefaultZoom,
                    onTap: (tapPosition, point) => _inspectPoint(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConstants.osmTileUrlTemplate,
                      userAgentPackageName: AppConstants.osmPackageUserAgent,
                    ),
                    if (_showHeatmap) CircleLayer(circles: _heatmapCircles),
                    if (_showZones)
                      PolygonLayer(
                        polygons: [
                          for (final zone in zonesAsync.value ?? const [])
                            Polygon(
                              points: [for (final p in zone.latLngPoints) ll.LatLng(p.$1, p.$2)],
                              color: zoneColor(zone.type).withValues(alpha: 0.25),
                              borderColor: zoneColor(zone.type),
                              borderStrokeWidth: 2,
                            ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_showServices)
                          for (final service in servicesAsync.value ?? const [])
                            if (service.type == NearbyServiceType.police || service.type == NearbyServiceType.hospital)
                              Marker(
                                point: ll.LatLng(service.latitude, service.longitude),
                                width: 28,
                                height: 28,
                                child: Icon(
                                  service.type == NearbyServiceType.police
                                      ? Icons.local_police
                                      : Icons.local_hospital,
                                  color: service.type == NearbyServiceType.police
                                      ? AppColors.infoBlue
                                      : AppColors.emergencyRed,
                                  size: 24,
                                ),
                              ),
                        if (_showSos)
                          for (final sos in sosAsync.value ?? const [])
                            Marker(
                              point: ll.LatLng(sos.location[1], sos.location[0]),
                              width: 24,
                              height: 24,
                              child: const Icon(Icons.emergency, color: AppColors.emergencyRed, size: 24),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_loadingScore || _inspectedScore != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: GlassCard(
                    variant: GlassCardVariant.cyan,
                    child: _loadingScore
                        ? const Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Computing Location Intelligence...', style: TextStyle(color: AppColors.darkTextPrimary)),
                            ],
                          )
                        : _SafetyScorePanel(score: _inspectedScore!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyScorePanel extends StatelessWidget {
  const _SafetyScorePanel({required this.score});

  final SafetyScoreEntity score;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              score.safetyScore.toStringAsFixed(0),
              style: TextStyle(color: riskColor(score.safetyLevel), fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(score.safetyLevel, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location Intelligence',
                  style: TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (score.recommendations.isNotEmpty)
                Text(
                  score.recommendations.first,
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
