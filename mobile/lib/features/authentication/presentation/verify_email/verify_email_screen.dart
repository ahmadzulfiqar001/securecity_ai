import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/buttons/app_button.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/widgets/glow_orb.dart';
import '../auth_notifier.dart';

/// Shown to a logged-in user whose email is not yet verified - the router's
/// `redirect` guard confines them here until they verify, matching the
/// Splash → Check Login → Email Verified? → Home flow.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;

  Future<void> _handleResend() async {
    final success = await ref.read(authNotifierProvider.notifier).sendEmailVerification();
    if (!mounted) return;

    if (success) {
      AppSnackbar.showSuccess(context, 'Verification email sent.');
    } else {
      final state = ref.read(authNotifierProvider);
      if (state.errorMessage != null) {
        AppSnackbar.showError(context, state.errorMessage!);
      }
    }
  }

  Future<void> _handleCheckVerified() async {
    setState(() => _checking = true);
    final verified = await ref.read(authNotifierProvider.notifier).checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);

    if (verified) {
      context.go(AppRoutes.home);
    } else {
      AppSnackbar.showError(context, 'Still not verified. Check your inbox and tap the link first.');
    }
  }

  Future<void> _handleSignOut() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final email = ref.read(firebaseAuthProvider).currentUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          GlowOrb(
            top: -100,
            right: -100,
            size: 300,
            blurRadius: 100,
            color: AppColors.accentCyan.withValues(alpha: 0.12),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                child: ResponsiveContent(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppConstants.paddingMedium),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.darkCard,
                                border: Border.all(color: AppColors.glassBorderCyan),
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_outlined,
                                size: 48,
                                color: AppColors.accentCyan,
                              ),
                            ).animate().scale(
                                  duration: motionDuration(context, AppDurations.slow),
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              'Verify Your Email',
                              style: AppTypography.darkHeadlineSmall.copyWith(letterSpacing: 1.1),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text(
                              'We sent a verification link to $email. Please verify your '
                              'address to continue using SecureCity AI.',
                              textAlign: TextAlign.center,
                              style: AppTypography.darkBodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      AppButton(
                        label: "I've Verified My Email",
                        isLoading: _checking,
                        onPressed: _handleCheckVerified,
                      ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: AppConstants.paddingMedium),
                      AppButton(
                        label: 'Resend Verification Email',
                        variant: AppButtonVariant.outlined,
                        isLoading: authState.isLoading && !_checking,
                        onPressed: _handleResend,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      AppButton(
                        label: 'Sign Out',
                        variant: AppButtonVariant.text,
                        onPressed: _handleSignOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
