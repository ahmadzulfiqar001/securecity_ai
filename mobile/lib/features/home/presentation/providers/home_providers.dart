import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../area_safety/domain/entities/area_safety_entity.dart';
import '../../../area_safety/presentation/providers/area_safety_providers.dart';

/// Nearest area-safety zone to the user's current position (or the first
/// available zone if location isn't ready yet - same fallback
/// `area_safety_screen.dart` uses). Home's "Live Safety Score" card renders
/// this instead of the old static placeholder score.
final nearestSafetyZoneProvider = Provider.autoDispose<AsyncValue<AreaSafetyEntity?>>((ref) {
  final zonesAsync = ref.watch(areaSafetyStreamProvider);
  final position = ref.watch(currentPositionProvider).value;

  return zonesAsync.whenData((zones) {
    if (zones.isEmpty) return null;
    if (position == null) return zones.first;

    final sorted = [...zones]
      ..sort((a, b) => Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            a.latitude,
            a.longitude,
          ).compareTo(Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            b.latitude,
            b.longitude,
          )));
    return sorted.first;
  });
});
