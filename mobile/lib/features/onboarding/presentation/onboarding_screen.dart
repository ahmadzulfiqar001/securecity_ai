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
import '../../../shared/cards/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'City Safety Monitoring',
      description:
          'Receive real-time notifications about crime, disaster warnings, and emergency situations in your vicinity.',
      icon: Icons.shield_outlined,
      accentColor: AppColors.accentCyan,
    ),
    OnboardingPageData(
      title: 'Instant SOS Response',
      description:
          'Trigger emergency warnings via a simple tap, voice commands, or shaking your phone. The nearest authorities will be dispatched instantly.',
      icon: Icons.sos_rounded,
      accentColor: AppColors.emergencyRed,
    ),
    OnboardingPageData(
      title: 'AI Navigation & Assistance',
      description:
          'Generate safe route recommendations avoiding crime hotspots, flood zones, and accidents. Discuss safety concerns with our AI Chatbot.',
      icon: Icons.psychology_outlined,
      accentColor: AppColors.accentCyan,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _finishOnboarding() {
    final storage = ref.read(storageServiceProvider);
    storage.saveOnboardingComplete(true);
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Dynamic Background Gradients
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.4),
                radius: 1.2,
                colors: [
                  _pages[_currentPage].accentColor.withValues(alpha: 0.15),
                  AppColors.darkBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header with Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingSmall,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SecureCity AI',
                        semanticsLabel: 'SecureCity AI onboarding',
                        style: AppTypography.darkTitleSmall.copyWith(letterSpacing: 1.5),
                      ),
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'Skip',
                          style: AppTypography.darkLabelLarge.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // PageView Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      final isEmergency = page.accentColor == AppColors.emergencyRed;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon container with Glassmorphism
                            Semantics(
                              label: page.title,
                              child: Container(
                                padding: const EdgeInsets.all(AppConstants.paddingXLarge),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.darkCard,
                                  border: Border.all(
                                    color: page.accentColor.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.accentColor.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(page.icon, size: 100, color: page.accentColor),
                              ),
                            ).animate(key: ValueKey('icon_$index')).scale(
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: AppConstants.paddingXLarge + 16),
                            // Glassmorphism card for Text content
                            GlassCard(
                              variant: isEmergency ? GlassCardVariant.emergency : GlassCardVariant.cyan,
                              borderRadius: AppConstants.borderRadiusXLarge,
                              padding: const EdgeInsets.all(AppConstants.paddingLarge),
                              child: Column(
                                children: [
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.darkHeadlineSmall.copyWith(letterSpacing: 1.1),
                                  ),
                                  const SizedBox(height: AppConstants.paddingMedium),
                                  Text(
                                    page.description,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.darkBodyLarge.copyWith(
                                      color: AppColors.darkTextSecondary,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(key: ValueKey('text_$index')).fadeIn(
                                  duration: AppDurations.slow,
                                  delay: AppDurations.fast,
                                ).slideY(begin: 0.1, end: 0),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Indicators & Action Button
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Semantics(
                        label: 'Page ${_currentPage + 1} of ${_pages.length}',
                        child: Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _pages[_currentPage].accentColor
                                    : AppColors.glassWhite20,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Action Button
                      FloatingActionButton.extended(
                        onPressed: () {
                          if (_currentPage == _pages.length - 1) {
                            _finishOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        backgroundColor: _pages[_currentPage].accentColor,
                        label: Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        icon: Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}
