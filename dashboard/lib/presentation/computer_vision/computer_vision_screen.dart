import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/result.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/cv_repository_impl.dart';
import '../../domain/entities/camera_stream_entity.dart';
import '../../domain/entities/detection_event_entity.dart';
import '../../domain/repositories/cv_repository.dart';
import '../widgets/app_state_view.dart';
import '../widgets/glass_card.dart';

final cvRepositoryProvider = Provider<CvRepository>((ref) {
  return CvRepositoryImpl(ref.watch(cvEngineDioProvider));
});

final cameraStreamsProvider = FutureProvider.autoDispose<List<CameraStreamEntity>>((ref) async {
  final result = await ref.watch(cvRepositoryProvider).listStreams();
  return switch (result) {
    Success(value: final v) => v,
    Error(message: final m) => throw Exception(m),
  };
});

final selectedCameraIdProvider = StateProvider.autoDispose<String?>((ref) => null);

final liveCameraEventsProvider = StreamProvider.autoDispose.family<DetectionEventEntity, String>((ref, cameraId) {
  return ref.watch(cvRepositoryProvider).watchCameraEvents(cameraId);
});

class ComputerVisionScreen extends ConsumerWidget {
  const ComputerVisionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(cameraStreamsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Computer Vision',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Live camera streams and real-time weapon, fire/smoke, crowd, vehicle, '
          'road accident, and suspicious-activity detection from cv_engine.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: streamsAsync.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => AppErrorView(
              message: 'Failed to reach cv_engine: $error',
              onRetry: () => ref.invalidate(cameraStreamsProvider),
            ),
            data: (streams) {
              if (streams.isEmpty) {
                return const AppEmptyView(
                  icon: Icons.videocam_off_outlined,
                  message: 'No camera streams registered yet.',
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final streamList = _StreamList(streams: streams);
                  final eventPanel = const _LiveEventPanel();

                  if (!isWide) {
                    return Column(
                      children: [
                        SizedBox(height: 220, child: streamList),
                        const SizedBox(height: 16),
                        Expanded(child: eventPanel),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: streamList),
                      const SizedBox(width: 16),
                      Expanded(child: eventPanel),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StreamList extends ConsumerWidget {
  const _StreamList({required this.streams});

  final List<CameraStreamEntity> streams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCameraIdProvider);

    return ListView.separated(
      itemCount: streams.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final stream = streams[index];
        final isSelected = stream.cameraId == selected;
        final isRunning = stream.status == 'running';

        return GestureDetector(
          onTap: () => ref.read(selectedCameraIdProvider.notifier).state = stream.cameraId,
          child: GlassCard(
            variant: isSelected ? GlassCardVariant.cyan : GlassCardVariant.surface,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isRunning ? AppColors.successGreen : AppColors.darkTextDisabled,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.cameraId,
                        style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stream.status} · ${stream.fps.toStringAsFixed(1)} fps',
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveEventPanel extends ConsumerStatefulWidget {
  const _LiveEventPanel();

  @override
  ConsumerState<_LiveEventPanel> createState() => _LiveEventPanelState();
}

class _LiveEventPanelState extends ConsumerState<_LiveEventPanel> {
  final List<DetectionEventEntity> _events = [];
  String? _listeningTo;

  void _resetIfCameraChanged(String? cameraId) {
    if (cameraId != _listeningTo) {
      _listeningTo = cameraId;
      _events.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraId = ref.watch(selectedCameraIdProvider);
    _resetIfCameraChanged(cameraId);

    if (cameraId == null) {
      return const AppEmptyView(
        icon: Icons.touch_app_outlined,
        message: 'Select a camera to view its live detection feed.',
      );
    }

    ref.listen(liveCameraEventsProvider(cameraId), (previous, next) {
      next.whenData((event) {
        if (!mounted) return;
        setState(() {
          _events.insert(0, event);
          if (_events.length > 100) _events.removeLast();
        });
      });
    });

    final liveAsync = ref.watch(liveCameraEventsProvider(cameraId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Live feed · $cameraId',
              style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 8),
            if (liveAsync.hasError)
              const Icon(Icons.wifi_off, color: AppColors.emergencyRed, size: 16)
            else
              const Icon(Icons.circle, color: AppColors.successGreen, size: 8),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _events.isEmpty
              ? const AppEmptyView(
                  icon: Icons.sensors_outlined,
                  message: 'Waiting for detection events...',
                )
              : ListView.separated(
                  itemCount: _events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _EventTile(event: _events[index]),
                ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final DetectionEventEntity event;

  Color get _severityColor {
    final label = event.primarySeverityLabel;
    return switch (label) {
      'WEAPON' || 'ACCIDENT' => AppColors.emergencyRed,
      'FIRE/SMOKE' => AppColors.emergencyOrange,
      'SUSPICIOUS' => AppColors.warningAmber,
      'CROWD' => AppColors.infoBlue,
      _ => AppColors.darkTextDisabled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final label = event.primarySeverityLabel;
    final dateFormat = DateFormat('h:mm:ss a');

    return GlassCard(
      variant: event.hasAlert ? GlassCardVariant.cyan : GlassCardVariant.surface,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _severityColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.detections.length} object(s) · ${event.fps.toStringAsFixed(1)} fps',
                  style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(event.timestamp),
                  style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _severityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _severityColor),
              ),
              child: Text(
                label,
                style: TextStyle(color: _severityColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
