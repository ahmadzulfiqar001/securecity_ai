import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:securecity_dashboard/core/errors/result.dart';
import 'package:securecity_dashboard/domain/entities/camera_stream_entity.dart';
import 'package:securecity_dashboard/domain/entities/detection_event_entity.dart';
import 'package:securecity_dashboard/domain/repositories/cv_repository.dart';
import 'package:securecity_dashboard/presentation/computer_vision/computer_vision_screen.dart';

class _FakeCvRepository implements CvRepository {
  _FakeCvRepository(this._streams);

  final List<CameraStreamEntity> _streams;

  @override
  Future<Result<List<CameraStreamEntity>>> listStreams() async => Success(_streams);

  @override
  Future<Result<List<DetectionEventEntity>>> recentDetections({String? cameraId, int limit = 50}) async =>
      const Success([]);

  @override
  Stream<DetectionEventEntity> watchCameraEvents(String cameraId) => const Stream.empty();
}

void main() {
  testWidgets('shows empty state when no camera streams are registered', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvRepositoryProvider.overrideWithValue(_FakeCvRepository(const [])),
        ],
        child: const MaterialApp(home: Scaffold(body: ComputerVisionScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No camera streams registered yet.'), findsOneWidget);
  });

  testWidgets('lists a registered camera stream and opens its live feed panel on tap', (tester) async {
    final stream = CameraStreamEntity(
      streamId: 'cam-1',
      cameraId: 'cam-1',
      rtspUrl: 'simulate',
      status: 'running',
      fps: 24.5,
      startedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cvRepositoryProvider.overrideWithValue(_FakeCvRepository([stream])),
        ],
        child: const MaterialApp(home: Scaffold(body: ComputerVisionScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('cam-1'), findsOneWidget);
    expect(find.text('Select a camera to view its live detection feed.'), findsOneWidget);

    await tester.tap(find.text('cam-1'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Live feed'), findsOneWidget);
    expect(find.text('Waiting for detection events...'), findsOneWidget);
  });
}
