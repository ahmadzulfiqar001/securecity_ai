import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/dialogs/app_snackbar.dart';
import '../../../shared/buttons/danger_button.dart';
import '../domain/entities/sos_event_entity.dart';
import 'providers/sos_providers.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  int _countdown = 3;
  Timer? _timer;
  bool _isSosTriggered = false;
  bool _isCountdownActive = true;
  String? _sosEventId;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        _triggerSos();
      } else {
        setState(() {
          _countdown--;
        });
        _vibrateTick();
      }
    });
    _vibrateTick();
  }

  Future<void> _vibrateTick() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 100);
    }
  }

  Future<void> _triggerSos() async {
    setState(() {
      _isCountdownActive = false;
      _isSosTriggered = true;
    });

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [500, 200, 500, 200, 1000]);
    }

    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentLocation();
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;

    if (pos == null || uid == null) return;

    final event = SosEventEntity(
      userId: uid,
      latitude: pos.latitude,
      longitude: pos.longitude,
      message: AppConstants.sosDefaultMessage,
      status: 'active',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    final result = await ref.read(sosRepositoryProvider).createSosEvent(event);
    if (!mounted) return;

    result.fold(
      onSuccess: (eventId) => setState(() => _sosEventId = eventId),
      onError: (failure) => AppSnackbar.showError(
        context,
        'Could not confirm SOS delivery: ${failure.message}. Retrying is recommended once you have signal.',
      ),
    );
  }

  Future<void> _cancelSos() async {
    _timer?.cancel();
    Vibration.cancel();

    final eventId = _sosEventId;
    if (eventId != null) {
      await ref.read(sosRepositoryProvider).resolveSosEvent(eventId);
    }

    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Radial red pulse background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.2,
                colors: [
                  _isSosTriggered
                      ? AppColors.emergencyRed.withValues(alpha: 0.3)
                      : AppColors.emergencyRed.withValues(alpha: 0.15),
                  AppColors.darkBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top info
                  Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          _isSosTriggered ? 'EMERGENCY ACTIVE' : 'TRIGGERING SOS',
                          style: AppTypography.emergencyLabel.copyWith(fontSize: 22, letterSpacing: 2),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Text(
                          _isSosTriggered
                              ? 'Your live location, audio, and video are being shared.'
                              : 'Dispatching nearest police & medical units in...',
                          textAlign: TextAlign.center,
                          style: AppTypography.darkBodyMedium,
                        ),
                      ],
                    ),
                  ),

                  // Center Button & Countdown
                  Center(
                    child: _isCountdownActive
                        ? _buildCountdownCircle()
                        : _buildPulsingSosButton(),
                  ),

                  // Bottom Controls & Contacts
                  Column(
                    children: [
                      if (!_isSosTriggered) ...[
                        OutlinedButton(
                          onPressed: _cancelSos,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(240, 52),
                          ),
                          child: const Text('CANCEL SOS'),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingLarge,
                            vertical: AppConstants.paddingMedium,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.emergencyRedGlow),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.radio_button_checked, color: AppColors.emergencyRed),
                              const SizedBox(width: 12),
                              Text(
                                'BROADCASTING LIVE...',
                                style: AppTypography.darkLabelLarge.copyWith(color: AppColors.emergencyRed),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        DangerButton(
                          label: 'I AM SAFE - END ALERTS',
                          onPressed: _cancelSos,
                        ),
                      ],
                      const SizedBox(height: AppConstants.paddingXLarge),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCircle() {
    return Semantics(
      label: 'SOS triggers in $_countdown seconds',
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkCard,
          border: Border.all(color: AppColors.emergencyRedGlow, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.emergencyRed.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 2,
            )
          ],
        ),
        child: Text('$_countdown', style: AppTypography.darkDisplaySmall.copyWith(fontSize: 72)),
      ),
    ).animate().scale(duration: motionDuration(context, 300.ms), curve: Curves.easeOutBack);
  }

  Widget _buildPulsingSosButton() {
    return Semantics(
      label: 'Emergency SOS active',
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.emergencyRed,
          boxShadow: [
            BoxShadow(
              color: AppColors.emergencyRed,
              blurRadius: 50,
              spreadRadius: 5,
            )
          ],
        ),
        child: const Icon(Icons.security, size: 80, color: AppColors.primaryDeepBlue),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.15, 1.15),
          duration: 600.ms,
          curve: Curves.easeInOut,
        );
  }
}
