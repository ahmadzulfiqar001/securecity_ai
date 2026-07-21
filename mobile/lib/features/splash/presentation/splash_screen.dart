import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/motion.dart';
import '../../../shared/widgets/glow_orb.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for the animation to play
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final storage = ref.read(storageServiceProvider);
    final auth = ref.read(firebaseAuthProvider);

    // 1. Check onboarding status
    final onboardingComplete = storage.isOnboardingComplete();
    if (!onboardingComplete) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // 2. Check authentication state
    final currentUser = auth.currentUser;
    if (currentUser != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Semantics(
        label: 'SecureCity AI is loading',
        child: Stack(
          children: [
            GlowOrb(
              top: -100,
              left: -100,
              size: 300,
              blurRadius: 100,
              color: AppColors.accentCyan.withValues(alpha: 0.15),
            ),
            const GlowOrb(
              bottom: -50,
              right: -50,
              size: 250,
              blurRadius: 80,
              color: AppColors.glassCyan10,
            ),
            // Centered branding
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Shield Logo
                  ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkCard,
                        border: Border.all(
                          color: AppColors.glassBorderCyan,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.glassCyan20,
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 80,
                        color: AppColors.accentCyan,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: motionDuration(context, 800.ms),
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .shimmer(
                          duration: motionDuration(context, 1500.ms),
                          color: AppColors.white.withValues(alpha: 0.24),
                        ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),
                  // Title
                  ExcludeSemantics(
                    child: Text(
                      'SECURECITY AI',
                      style: AppTypography.darkHeadlineLarge.copyWith(
                        fontSize: 28,
                        letterSpacing: 4,
                        shadows: const [
                          Shadow(color: AppColors.accentCyan, blurRadius: 10),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: motionDuration(context, 600.ms))
                        .slideY(begin: 0.2, end: 0),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  // Tagline
                  ExcludeSemantics(
                    child: Text(
                      'Smart Safety & Emergency Response',
                      style: AppTypography.darkBodyMedium.copyWith(letterSpacing: 1.2),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: motionDuration(context, 600.ms))
                        .slideY(begin: 0.2, end: 0),
                  ),
                ],
              ),
            ),
            // Loader at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentCyan.withValues(alpha: 0.7),
                    ),
                  ),
                ).animate().fadeIn(delay: AppDurations.slowest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
