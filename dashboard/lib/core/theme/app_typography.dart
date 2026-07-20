import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for the SecureCity AI Authority Dashboard using the
/// Inter font family, loaded at runtime via google_fonts (see pubspec.yaml).
/// Mirrors `mobile/lib/core/theme/app_typography.dart`'s scale and `_base()`
/// pattern — dark-only, since the dashboard has no light theme.
abstract final class AppTypography {
  static final String _fontFamily = GoogleFonts.inter().fontFamily!;

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: TextDecoration.none,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Text Styles
  // ─────────────────────────────────────────────────────────────────────────

  /// 57sp — Hero sections
  static final TextStyle displayLarge = _base(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: -0.25,
    height: 1.12,
  );

  /// 45sp — Screen-level headlines
  static final TextStyle displayMedium = _base(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.16,
  );

  /// 36sp — Section emphasis
  static final TextStyle displaySmall = _base(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.22,
  );

  /// 32sp — Card headers, large labels
  static final TextStyle headlineLarge = _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.25,
  );

  /// 28sp — Sub-section headers
  static final TextStyle headlineMedium = _base(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.29,
  );

  /// 24sp — Dialog titles, prominent labels
  static final TextStyle headlineSmall = _base(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.33,
  );

  /// 22sp — AppBar / page titles
  static final TextStyle titleLarge = _base(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.27,
  );

  /// 16sp — Card titles, list section headers
  static final TextStyle titleMedium = _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// 14sp — Item titles, button labels
  static final TextStyle titleSmall = _base(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// 16sp — Long-form readable text
  static final TextStyle bodyLarge = _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.5,
    height: 1.5,
  );

  /// 14sp — Supporting body text
  static final TextStyle bodyMedium = _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// 12sp — Captions, meta info
  static final TextStyle bodySmall = _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// 14sp — Button text, tab labels
  static final TextStyle labelLarge = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// 12sp — Chips, badges
  static final TextStyle labelMedium = _base(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.5,
    height: 1.33,
  );

  /// 11sp — Nav labels, tiny tags
  static final TextStyle labelSmall = _base(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextDisabled,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Accent / Colored Text Styles
  // ─────────────────────────────────────────────────────────────────────────

  static final TextStyle cyanHeadline = headlineMedium.copyWith(
    color: AppColors.accentCyan,
    letterSpacing: 1.2,
  );

  static final TextStyle emergencyLabel = _base(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.emergencyRed,
    letterSpacing: 1.5,
    height: 1.2,
  );

  static final TextStyle successLabel = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.successGreen,
    letterSpacing: 0.5,
    height: 1.43,
  );

  static final TextStyle warningLabel = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.warningAmber,
    letterSpacing: 0.5,
    height: 1.43,
  );

  static final TextStyle monospaceCode = _base(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.accentCyan,
    letterSpacing: 1.0,
    height: 1.5,
  ).copyWith(fontFamily: 'Courier New');

  // ─────────────────────────────────────────────────────────────────────────
  // TextTheme builder
  // ─────────────────────────────────────────────────────────────────────────

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
