import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/cards/glass_card.dart';
import '../../services/domain/entities/nearby_service_entity.dart';
import '../../services/presentation/providers/nearby_services_providers.dart';
import '../domain/entities/map_zone_entity.dart';
import '../domain/entities/route_safety_entity.dart';
import 'providers/map_providers.dart';

Color _riskColor(String riskLevel) => switch (riskLevel) {
      'CRITICAL' => AppColors.emergencyRed,
      'HIGH' => AppColors.emergencyOrange,
      'MEDIUM' => AppColors.warningAmber,
      _ => AppColors.successGreen,
    };

Color _zoneColor(String type, String severity) {
  final base = switch (type) {
    MapZoneType.emergency => AppColors.emergencyRed,
    MapZoneType.floodRisk => AppColors.infoBlue,
    MapZoneType.traffic => AppColors.warningAmber,
    _ => AppColors.darkTextSecondary,
  };
  final opacity = switch (severity) {
    'critical' => 0.35,
    'high' => 0.28,
    'medium' => 0.20,
    _ => 0.12,
  };
  return base.withValues(alpha: opacity);
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isHeatmapEnabled = false;
  bool _isPickingDestination = false;
  bool _isScoringRoute = false;

  List<CircleMarker> _heatmapCircles = [];
  LatLng? _destination;
  RouteSafetyEntity? _routeResult;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _currentPosition = pos;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleHeatmap() async {
    if (_isHeatmapEnabled) {
      setState(() {
        _isHeatmapEnabled = false;
        _heatmapCircles = [];
      });
      return;
    }

    final pos = _currentPosition;
    final center = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(24.8607, 67.0011);

    final result = await ref.read(predictionsRepositoryProvider).getCrimeHeatmap(
          minLat: center.latitude - 0.05,
          maxLat: center.latitude + 0.05,
          minLon: center.longitude - 0.05,
          maxLon: center.longitude + 0.05,
        );

    if (!mounted) return;

    switch (result) {
      case Success(value: final heatmap):
        setState(() {
          _isHeatmapEnabled = true;
          _heatmapCircles = heatmap.cells
              .map((cell) => CircleMarker(
                    point: LatLng(cell.lat, cell.lng),
                    radius: 120,
                    useRadiusInMeter: true,
                    color: _riskColor(cell.riskLevel).withValues(alpha: 0.35),
                    borderColor: _riskColor(cell.riskLevel),
                    borderStrokeWidth: 1,
                  ))
              .toList();
        });
      case Error(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load heatmap: ${failure.message}')),
        );
    }
  }

  void _startRoutePicking() {
    setState(() {
      _isPickingDestination = true;
      _destination = null;
      _routeResult = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tap a destination on the map')),
    );
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    if (!_isPickingDestination || _currentPosition == null) return;

    setState(() {
      _destination = point;
      _isPickingDestination = false;
      _isScoringRoute = true;
    });

    final result = await ref.read(predictionsRepositoryProvider).scoreRoute(
      coordinates: [
        [_currentPosition!.longitude, _currentPosition!.latitude],
        [point.longitude, point.latitude],
      ],
      hour: DateTime.now().hour,
    );

    if (!mounted) return;
    setState(() => _isScoringRoute = false);

    switch (result) {
      case Success(value: final route):
        setState(() => _routeResult = route);
      case Error(failure: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not score route: ${failure.message}')),
        );
    }
  }

  List<Polygon> _buildZonePolygons(List<MapZoneEntity> zones) {
    return zones.map((zone) {
      return Polygon(
        points: zone.latLngPoints.map((p) => LatLng(p.$1, p.$2)).toList(),
        color: _zoneColor(zone.type, zone.severity),
        borderColor: _zoneColor(zone.type, zone.severity).withValues(alpha: 0.8),
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  List<Marker> _buildServiceMarkers(List<NearbyServiceEntity> services) {
    return services
        .where((s) => s.type == NearbyServiceType.police || s.type == NearbyServiceType.hospital)
        .map((s) {
      final isPolice = s.type == NearbyServiceType.police;
      return Marker(
        point: LatLng(s.latitude, s.longitude),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${s.name} · ${NearbyServiceType.label(s.type)}')),
          ),
          child: Icon(
            isPolice ? Icons.local_police : Icons.local_hospital,
            color: isPolice ? AppColors.markerPolice : AppColors.markerHospital,
            size: 32,
          ),
        ),
      );
    }).toList();
  }

  List<Polyline> _buildRoutePolylines(RouteSafetyEntity route) {
    final points = route.segmentScores;
    final polylines = <Polyline>[];
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final level = a['safety_level'] as String? ?? 'MODERATE';
      polylines.add(Polyline(
        points: [
          LatLng((a['lat'] as num).toDouble(), (a['lon'] as num).toDouble()),
          LatLng((b['lat'] as num).toDouble(), (b['lon'] as num).toDouble()),
        ],
        color: switch (level) {
          'VERY_SAFE' || 'SAFE' => AppColors.successGreen,
          'MODERATE' => AppColors.warningAmber,
          _ => AppColors.emergencyRed,
        },
        strokeWidth: 5,
      ));
    }
    return polylines;
  }

  List<Marker> _buildDangerZoneMarkers(RouteSafetyEntity route) {
    return route.dangerZones.map((dz) {
      final lat = (dz['lat'] as num).toDouble();
      final lon = (dz['lon'] as num).toDouble();
      return Marker(
        point: LatLng(lat, lon),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Danger zone · score: ${dz['score']}')),
          ),
          child: const Icon(Icons.warning_rounded, color: AppColors.emergencyRed, size: 32),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(activeZonesStreamProvider);
    final servicesAsync = ref.watch(nearbyServicesStreamProvider);

    final markers = <Marker>[
      if (_currentPosition != null)
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 32,
          height: 32,
          child: const Icon(Icons.my_location, color: AppColors.markerUser, size: 28),
        ),
      if (_destination != null)
        Marker(
          point: _destination!,
          width: 36,
          height: 36,
          child: const Icon(Icons.location_on, color: AppColors.successGreen, size: 36),
        ),
      ...servicesAsync.value != null ? _buildServiceMarkers(servicesAsync.value!) : const <Marker>[],
      if (_routeResult != null) ..._buildDangerZoneMarkers(_routeResult!),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to home',
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: const Text('Safety & Threat Map'),
        actions: [
          IconButton(
            icon: Icon(
              _isHeatmapEnabled ? Icons.layers : Icons.layers_outlined,
              color: _isHeatmapEnabled ? AppColors.accentCyan : AppColors.darkTextPrimary,
            ),
            tooltip: _isHeatmapEnabled ? 'Hide crime heatmap' : 'Show crime heatmap',
            onPressed: _toggleHeatmap,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _currentPosition?.latitude ?? 24.8607,
                      _currentPosition?.longitude ?? 67.0011,
                    ),
                    initialZoom: 14,
                    onTap: _onMapTap,
                  ),
                  children: [
                    // OpenStreetMap tiles - free, no Google billing account required.
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ai.securecity.mobile',
                    ),
                    if (zonesAsync.value != null) PolygonLayer(polygons: _buildZonePolygons(zonesAsync.value!)),
                    if (_heatmapCircles.isNotEmpty) CircleLayer(circles: _heatmapCircles),
                    if (_routeResult != null) PolylineLayer(polylines: _buildRoutePolylines(_routeResult!)),
                    MarkerLayer(markers: markers),
                  ],
                ),

                if (_isPickingDestination)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          'Tap a destination on the map to score the route',
                          textAlign: TextAlign.center,
                          style: AppTypography.darkBodyMedium.copyWith(color: AppColors.darkTextPrimary),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: GlassCard(
                    borderRadius: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _routeResult == null ? Icons.security : Icons.route,
                              color: _routeResult == null
                                  ? AppColors.successGreen
                                  : (_routeResult!.hasDangerZones ? AppColors.emergencyRed : AppColors.successGreen),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AI Safe Route Guidance', style: AppTypography.darkTitleSmall),
                                  Text(
                                    _routeResult == null
                                        ? 'Tap to score a straight-line route to a destination.'
                                        : '${_routeResult!.overallLevel} · ${_routeResult!.recommendation}',
                                    style: AppTypography.darkBodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: (_isScoringRoute || _currentPosition == null) ? null : _startRoutePicking,
                          icon: _isScoringRoute
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.directions),
                          label: const Text('CALCULATE SAFE ROUTE'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
