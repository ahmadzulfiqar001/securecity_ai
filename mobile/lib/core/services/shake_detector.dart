import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final double shakeThresholdGravity;
  final int shakeSlopTimeMs;
  final int shakeCountResetTimeMs;
  final void Function() onShake;

  StreamSubscription? _subscription;
  int _lastShakeTimestamp = 0;
  int _shakeCount = 0;

  ShakeDetector({
    required this.onShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMs = 500,
    this.shakeCountResetTimeMs = 3000,
  });

  /// Starts listening to accelerometer sensor events.
  void startListening() {
    if (_subscription != null) return;

    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      final double gX = event.x / 9.80665;
      final double gY = event.y / 9.80665;
      final double gZ = event.z / 9.80665;

      // gForce will be close to 1 when there is no movement.
      final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThresholdGravity) {
        final int now = DateTime.now().millisecondsSinceEpoch;
        
        // Ignore shake events too close together
        if (_lastShakeTimestamp + shakeSlopTimeMs > now) {
          return;
        }

        // Reset shake count if last shake was too long ago
        if (_lastShakeTimestamp + shakeCountResetTimeMs < now) {
          _shakeCount = 0;
        }

        _lastShakeTimestamp = now;
        _shakeCount++;

        // Trigger on shake after 3 successive shakes to prevent false alarms
        if (_shakeCount >= 3) {
          onShake();
          _shakeCount = 0; // Reset count
        }
      }
    });
  }

  /// Stops listening to events.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
