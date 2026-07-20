import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/area_safety_repository_impl.dart';
import '../../domain/entities/area_safety_entity.dart';
import '../../domain/repositories/area_safety_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

final areaSafetyRepositoryProvider = Provider<AreaSafetyRepository>((ref) {
  return AreaSafetyRepositoryImpl(ref.watch(firestoreProvider));
});

final areaSafetyStreamProvider = StreamProvider.autoDispose<List<AreaSafetyEntity>>((ref) {
  return ref.watch(areaSafetyRepositoryProvider).watchAll();
});

class AreaSafetyScreen extends ConsumerWidget {
  const AreaSafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(areaSafetyStreamProvider);
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Area Safety')),
      body: zonesAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) => AppErrorView(message: 'Failed to load area safety data: $error'),
        data: (zones) {
          if (zones.isEmpty) {
            return const AppEmptyView(
              icon: Icons.shield_moon_outlined,
              message:
                  'No safety data available for your area yet.\nThe AI safety model is still being trained on this zone.',
            );
          }

          final position = positionAsync.value;
          final nearest = position == null
              ? zones.first
              : (zones.toList()
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
                    ))))
                  .first;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: _AreaSafetyCard(zone: nearest),
          );
        },
      ),
    );
  }
}

class _AreaSafetyCard extends StatelessWidget {
  const _AreaSafetyCard({required this.zone});

  final AreaSafetyEntity zone;

  Color get _scoreColor {
    if (zone.safetyScore >= AppConstants.safetyScoreSafeThreshold) return AppColors.successGreen;
    if (zone.safetyScore >= AppConstants.safetyScoreCautionThreshold) return AppColors.warningAmber;
    return AppColors.emergencyRed;
  }

  String get _label {
    if (zone.safetyScore >= AppConstants.safetyScoreSafeThreshold) return 'High Safety Score';
    if (zone.safetyScore >= AppConstants.safetyScoreCautionThreshold) return 'Moderate Safety Score';
    return 'Low Safety Score — Exercise Caution';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(zone.zoneName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: zone.safetyScore / AppConstants.safetyScoreMax,
                      strokeWidth: 8,
                      backgroundColor: AppColors.darkCardElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        zone.safetyScore.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('/100', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label, style: TextStyle(color: _scoreColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(zone.summary, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
