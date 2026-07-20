import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../interactive_map/interactive_map_screen.dart' show predictionsRepositoryProvider, riskColor;
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

/// Focused, heatmap-only view — reuses the same `predictionsRepositoryProvider`
/// (and its `getCrimeHeatmap()` call) that Interactive Map uses, rather than
/// duplicating the fetch logic.
class CrimeHeatmapScreen extends ConsumerStatefulWidget {
  const CrimeHeatmapScreen({super.key});

  @override
  ConsumerState<CrimeHeatmapScreen> createState() => _CrimeHeatmapScreenState();
}

class _CrimeHeatmapScreenState extends ConsumerState<CrimeHeatmapScreen> {
  List<CircleMarker> _circles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(predictionsRepositoryProvider).getCrimeHeatmap(
          minLat: AppConstants.mapDefaultLatitude - 0.1,
          maxLat: AppConstants.mapDefaultLatitude + 0.1,
          minLon: AppConstants.mapDefaultLongitude - 0.1,
          maxLon: AppConstants.mapDefaultLongitude + 0.1,
        );
    if (!mounted) return;
    switch (result) {
      case Success(value: final heatmap):
        setState(() {
          _loading = false;
          _circles = heatmap.cells
              .map((cell) => CircleMarker(
                    point: ll.LatLng(cell.lat, cell.lng),
                    radius: 90,
                    useRadiusInMeter: true,
                    color: riskColor(cell.riskLevel).withValues(alpha: 0.35),
                    borderColor: riskColor(cell.riskLevel),
                    borderStrokeWidth: 1,
                  ))
              .toList();
        });
      case Error(message: final message):
        setState(() {
          _loading = false;
          _error = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crime Heatmap',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'KDE-based crime density from ai_engine, refreshed on demand.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _error != null
              ? AppErrorView(message: 'Failed to load heatmap: $_error', onRetry: _load)
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: ll.LatLng(AppConstants.mapDefaultLatitude, AppConstants.mapDefaultLongitude),
                          initialZoom: AppConstants.mapDefaultZoom,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: AppConstants.osmTileUrlTemplate,
                            userAgentPackageName: AppConstants.osmPackageUserAgent,
                          ),
                          CircleLayer(circles: _circles),
                        ],
                      ),
                    ),
                    if (_loading) const Positioned.fill(child: AppLoadingView()),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            _LegendRow(color: AppColors.emergencyRed, label: 'Critical'),
                            _LegendRow(color: Colors.deepOrange, label: 'High'),
                            _LegendRow(color: AppColors.warningAmber, label: 'Medium'),
                            _LegendRow(color: AppColors.successGreen, label: 'Low'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
