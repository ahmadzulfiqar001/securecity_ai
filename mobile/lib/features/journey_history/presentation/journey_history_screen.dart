import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/cards/glass_card.dart';
import '../domain/entities/journey_entity.dart';
import 'providers/journey_history_providers.dart';

class JourneyHistoryScreen extends ConsumerWidget {
  const JourneyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeysAsync = ref.watch(journeyHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journey History')),
      body: journeysAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorState(message: 'Failed to load journey history: $error'),
        data: (journeys) {
          if (journeys.isEmpty) {
            return const EmptyState(
              icon: Icons.route_outlined,
              message:
                  'No tracked journeys yet.\nStart Live Journey Tracking from the map to record a trip.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: journeys.length,
            itemBuilder: (context, index) => _JourneyTile(journey: journeys[index]),
          );
        },
      ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  const _JourneyTile({required this.journey});

  final JourneyEntity journey;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    final isActive = journey.status == 'active';
    final distanceKm = journey.distanceMeters != null
        ? (journey.distanceMeters! / 1000).toStringAsFixed(1)
        : null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isActive ? AppColors.glassCyan10 : AppColors.darkCardElevated,
            child: Icon(
              isActive ? Icons.navigation : Icons.check_circle_outline,
              color: isActive ? AppColors.accentCyan : AppColors.darkTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormat.format(journey.startedAt)),
                const SizedBox(height: 4),
                Text(
                  distanceKm != null ? '$distanceKm km · ${journey.status}' : journey.status,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
