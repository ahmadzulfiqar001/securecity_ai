import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/routes/app_routes.dart';
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go(AppRoutes.home);
    } else if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.errorMessage != null) {
        AppSnackbar.showError(context, state.errorMessage!);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authNotifierProvider.notifier).loginWithGoogle();
    if (success && mounted) {
      context.go(AppRoutes.home);
    } else if (mounted) {
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
          GlowOrb(
            bottom: -80,
            left: -80,
            size: 250,
            blurRadius: 90,
            color: AppColors.accentCyan.withValues(alpha: 0.08),
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
                      // Brand Icon & Title
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
                                Icons.security_rounded,
                                size: 48,
                                color: AppColors.accentCyan,
                              ),
                            ).animate().scale(
                                  duration: motionDuration(context, AppDurations.slow),
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text('Welcome Back', style: AppTypography.darkHeadlineSmall.copyWith(letterSpacing: 1.1)),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text(
                              'Sign in to secure your urban journey',
                              style: AppTypography.darkBodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      // Glassmorphism login card
                      GlassCard(
                        borderRadius: AppConstants.borderRadiusXLarge,
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email input
                              AppTextField(
                                label: 'Email Address',
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.isEmpty || !val.contains('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),
                              // Password input
                              AppTextField(
                                label: 'Password',
                                controller: _passwordController,
                                icon: Icons.lock_outlined,
                                obscureText: true,
                                validator: (val) {
                                  if (val == null || val.isEmpty || val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push(AppRoutes.forgotPassword),
                                  child: Text(
                                    'Forgot Password?',
                                    style: AppTypography.darkBodySmall.copyWith(color: AppColors.accentCyan),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingSmall),
                              // Sign In Button
                              AppButton(
                                label: 'Sign In',
                                isLoading: authState.isLoading,
                                onPressed: _handleLogin,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: AppConstants.paddingLarge),
                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.darkDivider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                            child: Text('Or continue with', style: AppTypography.darkLabelMedium),
                          ),
                          const Expanded(child: Divider(color: AppColors.darkDivider)),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Google Sign-In button
                      OutlinedButton.icon(
                        onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text('Sign In with Google'),
                      ),
                      const SizedBox(height: AppConstants.paddingXLarge),
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ", style: AppTypography.darkBodyMedium),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.register),
                            child: Text(
                              'Sign Up',
                              style: AppTypography.darkBodyMedium.copyWith(
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
