import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/buttons/app_button.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/cards/glass_card.dart';
import '../../../../shared/inputs/app_text_field.dart';
import '../../../../shared/widgets/glow_orb.dart';
import '../auth_notifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (!mounted) return;

    if (success) {
      setState(() => _emailSent = true);
    } else {
      final state = ref.read(authNotifierProvider);
      if (state.errorMessage != null) {
        AppSnackbar.showError(context, state.errorMessage!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

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
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to sign in',
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
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
                              child: Icon(
                                _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset_outlined,
                                size: 48,
                                color: AppColors.accentCyan,
                              ),
                            ).animate().scale(
                                  duration: motionDuration(context, AppDurations.slow),
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              _emailSent ? 'Check Your Email' : 'Forgot Password',
                              style: AppTypography.darkHeadlineSmall.copyWith(letterSpacing: 1.1),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text(
                              _emailSent
                                  ? 'A password reset link has been sent to ${_emailController.text.trim()}.'
                                  : 'Enter your email and we will send you a link to reset your password.',
                              textAlign: TextAlign.center,
                              style: AppTypography.darkBodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      if (!_emailSent)
                        GlassCard(
                          borderRadius: AppConstants.borderRadiusXLarge,
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  onFieldSubmitted: (_) => _handleSendResetEmail(),
                                  validator: (val) {
                                    if (val == null || val.isEmpty || !val.contains('@')) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppConstants.paddingLarge),
                                AppButton(
                                  label: 'Send Reset Link',
                                  isLoading: authState.isLoading,
                                  onPressed: _handleSendResetEmail,
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0)
                      else
                        AppButton(
                          label: 'Back to Sign In',
                          onPressed: () => context.pop(),
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
