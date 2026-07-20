import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/emergency_queue_repository_impl.dart';
import '../../domain/entities/sos_event_entity.dart';
import '../../domain/repositories/emergency_queue_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

final emergencyQueueRepositoryProvider = Provider<EmergencyQueueRepository>((ref) {
  return EmergencyQueueRepositoryImpl(ref.watch(firestoreProvider));
});

final emergencyQueueStreamProvider = StreamProvider.autoDispose<List<SosEventEntity>>((ref) {
  return ref.watch(emergencyQueueRepositoryProvider).watchActive();
});

class EmergencyQueueScreen extends ConsumerWidget {
  const EmergencyQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(emergencyQueueStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Queue',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Live SOS alerts awaiting acknowledgement, most recent first.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: queueAsync.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => AppErrorView(message: 'Failed to load emergency queue: $error'),
            data: (events) {
              if (events.isEmpty) {
                return const AppEmptyView(
                  icon: Icons.emergency_outlined,
                  message: 'No active SOS alerts.',
                );
              }
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) => _SosTile(event: events[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SosTile extends ConsumerWidget {
  const _SosTile({required this.event});

  final SosEventEntity event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, h:mm:ss a');

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      variant: GlassCardVariant.cyan,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.emergencyRed, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS · User ${event.userId}',
                  style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateFormat.format(event.createdAt)} · ${event.location[1].toStringAsFixed(4)}, ${event.location[0].toStringAsFixed(4)}',
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                ),
                if (event.message != null) ...[
                  const SizedBox(height: 4),
                  Text(event.message!, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
              if (uid == null) return;
              await ref.read(emergencyQueueRepositoryProvider).acknowledge(event.id, uid);
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }
}
