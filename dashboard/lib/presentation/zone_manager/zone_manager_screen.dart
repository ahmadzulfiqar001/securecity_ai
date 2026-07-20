import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/constants/app_constants.dart';
import '../../core/errors/result.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/map_zone_repository_impl.dart';
import '../../domain/entities/map_zone_entity.dart';
import '../../domain/repositories/map_zone_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

final mapZoneRepositoryProvider = Provider<MapZoneRepository>((ref) {
  return MapZoneRepositoryImpl(ref.watch(firestoreProvider));
});

final mapZonesStreamProvider = StreamProvider.autoDispose<List<MapZoneEntity>>((ref) {
  return ref.watch(mapZoneRepositoryProvider).watchAll();
});

Color zoneColor(String type) => switch (type) {
      MapZoneType.emergency => AppColors.emergencyRed,
      MapZoneType.floodRisk => Colors.blueAccent,
      MapZoneType.traffic => AppColors.warningAmber,
      _ => AppColors.darkTextSecondary,
    };

/// Full-screen zone editor, reached from Interactive Map. Draw a polygon by
/// tapping the map, then fill in its type/severity/description and save.
class ZoneManagerScreen extends ConsumerStatefulWidget {
  const ZoneManagerScreen({super.key});

  @override
  ConsumerState<ZoneManagerScreen> createState() => _ZoneManagerScreenState();
}

class _ZoneManagerScreenState extends ConsumerState<ZoneManagerScreen> {
  final List<ll.LatLng> _drawingPoints = [];
  MapZoneEntity? _editingZone;

  void _onMapTap(TapPosition tapPosition, ll.LatLng point) {
    if (_editingZone == null && _drawingPoints.isEmpty) return; // not in draw mode
    setState(() => _drawingPoints.add(point));
  }

  void _startDrawing() {
    setState(() {
      _editingZone = null;
      _drawingPoints
        ..clear()
        ..add(ll.LatLng(AppConstants.mapDefaultLatitude, AppConstants.mapDefaultLongitude));
    });
  }

  void _editZone(MapZoneEntity zone) {
    setState(() {
      _editingZone = zone;
      _drawingPoints
        ..clear()
        ..addAll(zone.latLngPoints.map((p) => ll.LatLng(p.$1, p.$2)));
    });
  }

  void _cancelDrawing() {
    setState(() {
      _editingZone = null;
      _drawingPoints.clear();
    });
  }

  Future<void> _saveZone() async {
    if (_drawingPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A zone needs at least 3 points — tap the map to add more.')),
      );
      return;
    }

    final saved = await showDialog<_ZoneFormResult>(
      context: context,
      builder: (context) => _ZoneFormDialog(initial: _editingZone),
    );
    if (saved == null) return;

    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
    final polygon = _drawingPoints.map((p) => [p.longitude, p.latitude]).toList();

    final zone = MapZoneEntity(
      id: _editingZone?.id ?? '',
      name: saved.name,
      type: saved.type,
      polygon: polygon,
      severity: saved.severity,
      description: saved.description,
      trafficZoneId: saved.trafficZoneId,
      active: true,
      createdBy: _editingZone?.createdBy ?? uid,
      updatedAt: DateTime.now(),
    );

    final repository = ref.read(mapZoneRepositoryProvider);
    final result = _editingZone != null ? await repository.updateZone(zone) : await repository.createZone(zone);

    if (!mounted) return;
    switch (result) {
      case Success():
        _cancelDrawing();
      case Error(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteZone(String zoneId) async {
    final result = await ref.read(mapZoneRepositoryProvider).deleteZone(zoneId);
    if (!mounted) return;
    if (result case Error(message: final message)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(mapZonesStreamProvider);
    final isDrawing = _editingZone != null || _drawingPoints.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone Manager',
                    style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Draw emergency, flood-risk, and traffic zones for mobile display and geofencing.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            if (!isDrawing)
              ElevatedButton.icon(
                onPressed: _startDrawing,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('New Zone'),
              )
            else ...[
              OutlinedButton(onPressed: _cancelDrawing, child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _saveZone, child: const Text('Finish & Save')),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: ll.LatLng(AppConstants.mapDefaultLatitude, AppConstants.mapDefaultLongitude),
                      initialZoom: AppConstants.mapDefaultZoom,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConstants.osmTileUrlTemplate,
                        userAgentPackageName: AppConstants.osmPackageUserAgent,
                      ),
                      PolygonLayer(
                        polygons: [
                          for (final zone in zonesAsync.value ?? const <MapZoneEntity>[])
                            if (zone.id != _editingZone?.id)
                              Polygon(
                                points: [for (final p in zone.latLngPoints) ll.LatLng(p.$1, p.$2)],
                                color: zoneColor(zone.type).withValues(alpha: 0.25),
                                borderColor: zoneColor(zone.type),
                                borderStrokeWidth: 2,
                              ),
                          if (_drawingPoints.length >= 2)
                            Polygon(
                              points: _drawingPoints,
                              color: AppColors.accentCyan.withValues(alpha: 0.2),
                              borderColor: AppColors.accentCyan,
                              borderStrokeWidth: 2,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          for (final point in _drawingPoints)
                            Marker(
                              point: point,
                              width: 14,
                              height: 14,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(color: AppColors.accentCyan, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: zonesAsync.when(
                  loading: () => const AppLoadingView(),
                  error: (error, _) => AppErrorView(message: 'Failed to load zones: $error'),
                  data: (zones) {
                    if (zones.isEmpty) {
                      return const AppEmptyView(icon: Icons.map_outlined, message: 'No zones drawn yet.');
                    }
                    return ListView.separated(
                      itemCount: zones.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: zoneColor(zone.type), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(zone.name,
                                        style: const TextStyle(
                                            color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold)),
                                    Text('${MapZoneType.label(zone.type)} · ${zone.severity}',
                                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _editZone(zone),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.emergencyRed),
                                onPressed: () => _deleteZone(zone.id),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoneFormResult {
  _ZoneFormResult({
    required this.name,
    required this.type,
    required this.severity,
    this.description,
    this.trafficZoneId,
  });

  final String name;
  final String type;
  final String severity;
  final String? description;
  final String? trafficZoneId;
}

class _ZoneFormDialog extends StatefulWidget {
  const _ZoneFormDialog({this.initial});

  final MapZoneEntity? initial;

  @override
  State<_ZoneFormDialog> createState() => _ZoneFormDialogState();
}

class _ZoneFormDialogState extends State<_ZoneFormDialog> {
  late final _nameController = TextEditingController(text: widget.initial?.name);
  late final _descriptionController = TextEditingController(text: widget.initial?.description);
  late final _trafficZoneIdController = TextEditingController(text: widget.initial?.trafficZoneId);
  late String _type = widget.initial?.type ?? MapZoneType.emergency;
  late String _severity = widget.initial?.severity ?? MapZoneSeverity.medium;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'New Zone' : 'Edit Zone'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Zone name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in MapZoneType.all)
                  DropdownMenuItem(value: type, child: Text(MapZoneType.label(type))),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: [
                for (final severity in MapZoneSeverity.all)
                  DropdownMenuItem(value: severity, child: Text(severity)),
              ],
              onChanged: (value) => setState(() => _severity = value ?? _severity),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
            ),
            if (_type == MapZoneType.traffic) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _trafficZoneIdController,
                decoration: const InputDecoration(
                  labelText: 'Traffic zone_id',
                  helperText: 'Matches a TrafficPredictor zone_id (e.g. zone_a)',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.of(context).pop(_ZoneFormResult(
              name: _nameController.text.trim(),
              type: _type,
              severity: _severity,
              description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              trafficZoneId:
                  _trafficZoneIdController.text.trim().isEmpty ? null : _trafficZoneIdController.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
