import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/app_providers.dart';

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

    // Start uploading GPS, video/audio evidence, notifying contacts, etc.
    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentLocation();
    
    // In a real-world scenario, we publish to Firebase Firestore:
    // Firestore.instance.collection('active_sos').doc(userId).set({ ... })
    // For now, print location
    if (pos != null) {
      debugPrint("SOS Sent! Location: Lat ${pos.latitude}, Lng ${pos.longitude}");
    }
  }

  void _cancelSos() {
    _timer?.cancel();
    Vibration.cancel();
    context.pop();
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
                      ? AppColors.emergencyRed.withOpacity(0.3)
                      : AppColors.emergencyRed.withOpacity(0.15),
                  AppColors.darkBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top info
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        _isSosTriggered ? 'EMERGENCY ACTIVE' : 'TRIGGERING SOS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSosTriggered
                            ? 'Your live location, audio, and video are being shared.'
                            : 'Dispatching nearest police & medical units in...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
                        ElevatedButton(
                          onPressed: _cancelSos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'CANCEL SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.radio_button_checked, color: AppColors.emergencyRed),
                              SizedBox(width: 12),
                              Text(
                                'BROADCASTING LIVE...',
                                style: TextStyle(
                                  color: AppColors.emergencyRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cancelSos,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'I AM SAFE - END ALERTS',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
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
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 2,
          )
        ],
      ),
      child: Text(
        '$_countdown',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.bold,
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildPulsingSosButton() {
    return Container(
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
      child: const Icon(
        Icons.security,
        size: 80,
        color: Colors.black,
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
