import 'package:flutter/material.dart';

/// Returns [duration] unless the platform's "reduce motion" accessibility
/// setting is enabled (`MediaQuery.disableAnimations`), in which case it
/// returns [Duration.zero] so `flutter_animate` entrance animations become
/// instant instead of forcing motion on users who've asked to avoid it.
Duration motionDuration(BuildContext context, Duration duration) {
  return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
}
