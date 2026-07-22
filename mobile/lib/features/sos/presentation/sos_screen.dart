import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/storage_upload_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/dialogs/app_snackbar.dart';
import '../../../shared/buttons/emergency_button.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../emergency_contacts/presentation/providers/emergency_contacts_providers.dart';
import '../domain/entities/sos_event_entity.dart';
import '../domain/repositories/sos_repository.dart';
import 'providers/sos_providers.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  Timer? _holdVibrationTimer;
  StreamSubscription<Position>? _locationSubscription;
  int _holdSeconds = AppConstants.sosCountdownDefaultSeconds;
  bool _isHolding = false;
  bool _isSosTriggered = false;
  String? _sosEventId;
  AudioRecorder? _audioRecorder;

  @override
  void initState() {
    super.initState();
    _holdSeconds = ref.read(storageServiceProvider).getSosCountdownSeconds();
    _holdController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _holdSeconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _holdVibrationTimer?.cancel();
          _triggerSos();
        }
      });
  }

  void _onHoldDown() {
    if (_isSosTriggered) return;
    setState(() => _isHolding = true);
    _holdController.forward();
    _holdVibrationTimer = Timer.periodic(const Duration(milliseconds: 400), (_) => _vibrateTick());
  }

  void _onHoldRelease() {
    if (_isSosTriggered) return;
    _holdVibrationTimer?.cancel();
    if (_holdController.status != AnimationStatus.completed) {
      _holdController.reverse();
    }
    setState(() => _isHolding = false);
  }

  Future<void> _vibrateTick() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 100);
    }
  }

  Future<void> _triggerSos() async {
    setState(() {
      _isHolding = false;
      _isSosTriggered = true;
    });

    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [500, 200, 500, 200, 1000]);
    }

    unawaited(_startAudioRecording());

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
      onSuccess: (eventId) {
        setState(() => _sosEventId = eventId);
        _startLiveLocationUpdates(eventId);
        unawaited(_notifyEmergencyContactsBySms(pos.latitude, pos.longitude));
      },
      onError: (failure) => AppSnackbar.showError(
        context,
        'Could not confirm SOS delivery: ${failure.message}. Retrying is recommended once you have signal.',
      ),
    );
  }

  /// Keeps the SOS event's position current for as long as the alert is
  /// active, instead of only recording the position at trigger time.
  void _startLiveLocationUpdates(String eventId) {
    final locationService = ref.read(locationServiceProvider);
    final stream = locationService.startLocationStream(distanceFilter: 20, timeInterval: 10);
    _locationSubscription = stream?.listen((position) {
      ref.read(sosRepositoryProvider).updateLocation(eventId, position.latitude, position.longitude);
    });
  }

  /// Opens the device's SMS composer pre-filled with every saved emergency
  /// contact and a location link. There is no backend in this app to send
  /// a silent push to another person's device, so this - one tap to send,
  /// in the native Messages app - is the real notification path.
  Future<void> _notifyEmergencyContactsBySms(double lat, double lng) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    try {
      final contacts = await ref.read(emergencyContactsRepositoryProvider).watchContacts(uid).first;
      if (contacts.isEmpty) return;

      final locationMessage = AppConstants.sosLocationMessage
          .replaceAll('{lat}', lat.toStringAsFixed(6))
          .replaceAll('{lng}', lng.toStringAsFixed(6));
      final message = '${AppConstants.sosDefaultMessage} $locationMessage';
      final numbers = contacts.map((c) => c.phone).join(',');

      final uri = Uri(scheme: 'sms', path: numbers, queryParameters: {'body': message});
      await launchUrl(uri);
    } catch (_) {
      // Non-fatal: the SOS event itself is already recorded regardless.
    }
  }

  Future<void> _cancelSos() async {
    _holdController.stop();
    _holdVibrationTimer?.cancel();
    Vibration.cancel();
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    final eventId = _sosEventId;
    final sosRepo = ref.read(sosRepositoryProvider);
    final uploadService = ref.read(storageUploadServiceProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;

    final audioPath = await _stopAudioRecording();

    if (eventId != null) {
      await sosRepo.resolveSosEvent(eventId);
      if (audioPath != null && uid != null) {
        // Fire-and-forget: don't block dismissing the SOS screen on the
        // upload - it has no bearing on the emergency response itself.
        unawaited(_uploadAudioEvidence(sosRepo, uploadService, uid, eventId, audioPath));
      }
    }

    if (mounted) context.pop();
  }

  /// Starts capturing ambient audio as SOS evidence the moment an alert is
  /// triggered. Best-effort only - a denied mic permission or recorder
  /// failure must never block the emergency dispatch flow above.
  Future<void> _startAudioRecording() async {
    try {
      final recorder = AudioRecorder();
      if (!await recorder.hasPermission()) {
        recorder.dispose();
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      if (!mounted) {
        await recorder.stop();
        recorder.dispose();
        return;
      }
      _audioRecorder = recorder;
    } catch (_) {
      // No audio evidence this time - the rest of the SOS flow is unaffected.
    }
  }

  Future<String?> _stopAudioRecording() async {
    final recorder = _audioRecorder;
    _audioRecorder = null;
    if (recorder == null) return null;
    try {
      return await recorder.stop();
    } catch (_) {
      return null;
    } finally {
      recorder.dispose();
    }
  }

  Future<void> _uploadAudioEvidence(
    SosRepository sosRepo,
    StorageUploadService uploadService,
    String uid,
    String eventId,
    String audioPath,
  ) async {
    try {
      final fileName = audioPath.split(Platform.pathSeparator).last;
      final storagePath = '${AppConstants.storageSosAudio}/$uid/$eventId/$fileName';
      final url = await uploadService.uploadFile(
        path: storagePath,
        file: File(audioPath),
        contentType: 'audio/mp4',
      );
      await sosRepo.attachAudioEvidence(eventId, url);
    } catch (_) {
      // Non-fatal: the SOS event is already resolved either way.
    }
  }

  @override
  void dispose() {
    _holdController.dispose();
    _holdVibrationTimer?.cancel();
    _locationSubscription?.cancel();
    _audioRecorder?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: GradientBackground(
        accentColor: AppColors.emergencyRed,
        intensity: _isSosTriggered ? 0.3 : 0.15,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top info
                Column(
                  children: [
                    if (!_isSosTriggered)
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: () => context.pop(),
                        ),
                      ),
                    Semantics(
                      liveRegion: true,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            _isSosTriggered
                                ? 'EMERGENCY ACTIVE'
                                : (_isHolding ? 'KEEP HOLDING…' : AppStrings.sosHoldToActivate),
                            style: AppTypography.emergencyLabel.copyWith(fontSize: 22, letterSpacing: 2),
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          Text(
                            _isSosTriggered
                                ? 'Your live location and audio are being shared.'
                                : 'Press and hold the button below for $_holdSeconds seconds to send an emergency alert.',
                            textAlign: TextAlign.center,
                            style: AppTypography.darkBodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Center Button
                Center(
                  child: _isSosTriggered ? _buildPulsingSosButton() : _buildHoldButton(),
                ),

                // Bottom Controls & Contacts
                Column(
                  children: [
                    if (_isSosTriggered) ...[
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
                      EmergencyButton(
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
      ),
    );
  }

  Widget _buildHoldButton() {
    return Semantics(
      label: 'Hold to activate emergency SOS. Hold for $_holdSeconds seconds.',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _onHoldDown(),
        onTapUp: (_) => _onHoldRelease(),
        onTapCancel: _onHoldRelease,
        child: AnimatedBuilder(
          animation: _holdController,
          builder: (context, _) {
            final remaining = (_holdSeconds - _holdController.value * _holdSeconds).ceil();
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: _holdController.value,
                      strokeWidth: 8,
                      backgroundColor: AppColors.darkCard,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emergencyRed),
                    ),
                  ),
                  Container(
                    width: 180,
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergencyRed.withValues(alpha: _isHolding ? 1.0 : 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isHolding
                        ? Text(
                            '$remaining',
                            style: AppTypography.darkDisplaySmall.copyWith(fontSize: 56, color: AppColors.white),
                          )
                        : const Icon(Icons.security, size: 64, color: AppColors.primaryDeepBlue),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
