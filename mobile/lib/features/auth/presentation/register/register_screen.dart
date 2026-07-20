import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          GlowOrb(
            top: -100,
            left: -100,
            size: 300,
            blurRadius: 100,
            color: AppColors.accentCyan.withValues(alpha: 0.12),
          ),
          GlowOrb(
            bottom: -80,
            right: -80,
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
                      // Back button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back to sign in',
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall),
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Create Account',
                              style: AppTypography.darkHeadlineSmall.copyWith(fontSize: 28, letterSpacing: 1.1),
                            ),
                            const SizedBox(height: AppConstants.paddingSmall),
                            Text('Join SecureCity AI to stay protected', style: AppTypography.darkBodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingXLarge - 4),
                      // Form
                      GlassCard(
                        borderRadius: AppConstants.borderRadiusXLarge,
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full Name input
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.accentCyan),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty || val.length < 2) {
                                    return 'Enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),
                              // Phone input
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accentCyan),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty || val.length < 9) {
                                    return 'Enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),
                              // Email input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.accentCyan),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty || !val.contains('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),
                              // Password input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.accentCyan),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    ),
                                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty || val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppConstants.paddingLarge),
                              // Register Button
                              ElevatedButton(
                                onPressed: authState.isLoading ? null : _handleRegister,
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryDeepBlue,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Sign Up'),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: motionDuration(context, AppDurations.pageTransition)).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: AppConstants.paddingLarge),
                      // Back to login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ', style: AppTypography.darkBodyMedium),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Text(
                              'Sign In',
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
