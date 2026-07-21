import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../nearby_services/domain/entities/nearby_service_entity.dart';
import '../../nearby_services/presentation/providers/nearby_services_providers.dart';
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
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isHeatmapEnabled = false;
  bool _isPickingDestination = false;
  bool _isScoringRoute = false;

  Set<Circle> _heatmapCircles = {};
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

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  Future<void> _toggleHeatmap() async {
    if (_isHeatmapEnabled) {
      setState(() {
        _isHeatmapEnabled = false;
        _heatmapCircles = {};
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
              .map((cell) => Circle(
                    circleId: CircleId('heat_${cell.lat}_${cell.lng}'),
                    center: LatLng(cell.lat, cell.lng),
                    radius: 120,
                    fillColor: _riskColor(cell.riskLevel).withValues(alpha: 0.35),
                    strokeColor: _riskColor(cell.riskLevel),
                    strokeWidth: 1,
                  ))
              .toSet();
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

  Future<void> _onMapTap(LatLng position) async {
    if (!_isPickingDestination || _currentPosition == null) return;

    setState(() {
      _destination = position;
      _isPickingDestination = false;
      _isScoringRoute = true;
    });

    final result = await ref.read(predictionsRepositoryProvider).scoreRoute(
      coordinates: [
        [_currentPosition!.longitude, _currentPosition!.latitude],
        [position.longitude, position.latitude],
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

  Set<Polygon> _buildZonePolygons(List<MapZoneEntity> zones) {
    return zones.map((zone) {
      return Polygon(
        polygonId: PolygonId(zone.id),
        points: zone.latLngPoints.map((p) => LatLng(p.$1, p.$2)).toList(),
        fillColor: _zoneColor(zone.type, zone.severity),
        strokeColor: _zoneColor(zone.type, zone.severity).withValues(alpha: 0.8),
        strokeWidth: 2,
        consumeTapEvents: false,
      );
    }).toSet();
  }

  Set<Marker> _buildServiceMarkers(List<NearbyServiceEntity> services) {
    return services
        .where((s) => s.type == NearbyServiceType.police || s.type == NearbyServiceType.hospital)
        .map((s) => Marker(
              markerId: MarkerId('service_${s.id}'),
              position: LatLng(s.latitude, s.longitude),
              infoWindow: InfoWindow(title: s.name, snippet: NearbyServiceType.label(s.type)),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                s.type == NearbyServiceType.police ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRose,
              ),
            ))
        .toSet();
  }

  Set<Polyline> _buildRoutePolylines(RouteSafetyEntity route) {
    final points = route.segmentScores;
    final polylines = <Polyline>{};
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final level = a['safety_level'] as String? ?? 'MODERATE';
      polylines.add(Polyline(
        polylineId: PolylineId('route_seg_$i'),
        points: [
          LatLng((a['lat'] as num).toDouble(), (a['lon'] as num).toDouble()),
          LatLng((b['lat'] as num).toDouble(), (b['lon'] as num).toDouble()),
        ],
        color: switch (level) {
          'VERY_SAFE' || 'SAFE' => AppColors.successGreen,
          'MODERATE' => AppColors.warningAmber,
          _ => AppColors.emergencyRed,
        },
        width: 5,
      ));
    }
    return polylines;
  }

  Set<Marker> _buildDangerZoneMarkers(RouteSafetyEntity route) {
    return route.dangerZones.map((dz) {
      final lat = (dz['lat'] as num).toDouble();
      final lon = (dz['lon'] as num).toDouble();
      return Marker(
        markerId: MarkerId('danger_${lat}_$lon'),
        position: LatLng(lat, lon),
        infoWindow: InfoWindow(title: 'Danger zone', snippet: 'Score: ${dz['score']}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(activeZonesStreamProvider);
    final servicesAsync = ref.watch(nearbyServicesStreamProvider);

    final markers = <Marker>{
      if (_currentPosition != null)
        Marker(
          markerId: const MarkerId('current_loc'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (_destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      ...servicesAsync.value != null ? _buildServiceMarkers(servicesAsync.value!) : const <Marker>{},
      if (_routeResult != null) ..._buildDangerZoneMarkers(_routeResult!),
    };

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
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onTap: _onMapTap,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 24.8607,
                      _currentPosition?.longitude ?? 67.0011,
                    ),
                    zoom: 14,
                  ),
                  markers: markers,
                  circles: _heatmapCircles,
                  polygons: zonesAsync.value != null ? _buildZonePolygons(zonesAsync.value!) : {},
                  polylines: _routeResult != null ? _buildRoutePolylines(_routeResult!) : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
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
