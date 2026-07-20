import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for SecureCity AI using the Inter font family,
/// loaded at runtime via google_fonts (see pubspec.yaml).
abstract final class AppTypography {
  // ─────────────────────────────────────────────────────────────────────────
  // Base Text Style
  // ─────────────────────────────────────────────────────────────────────────
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
  // Dark Theme Text Styles
  // ─────────────────────────────────────────────────────────────────────────

  /// 57sp — App name, hero sections
  static final TextStyle darkDisplayLarge = _base(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: -0.25,
    height: 1.12,
  );

  /// 45sp — Screen-level headlines
  static final TextStyle darkDisplayMedium = _base(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.16,
  );

  /// 36sp — Section emphasis
  static final TextStyle darkDisplaySmall = _base(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.22,
  );

  /// 32sp — Card headers, large labels
  static final TextStyle darkHeadlineLarge = _base(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.25,
  );

  /// 28sp — Sub-section headers
  static final TextStyle darkHeadlineMedium = _base(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.29,
  );

  /// 24sp — Dialog titles, prominent labels
  static final TextStyle darkHeadlineSmall = _base(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.33,
  );

  /// 22sp — AppBar titles
  static final TextStyle darkTitleLarge = _base(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0,
    height: 1.27,
  );

  /// 16sp — Card titles, list section headers
  static final TextStyle darkTitleMedium = _base(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// 14sp — Item titles, button labels
  static final TextStyle darkTitleSmall = _base(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// 16sp — Long-form readable text
  static final TextStyle darkBodyLarge = _base(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.5,
    height: 1.5,
  );

  /// 14sp — Supporting body text
  static final TextStyle darkBodyMedium = _base(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// 12sp — Captions, meta info
  static final TextStyle darkBodySmall = _base(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// 14sp — Button text, tab labels
  static final TextStyle darkLabelLarge = _base(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkTextPrimary,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// 12sp — Chips, badges
  static final TextStyle darkLabelMedium = _base(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.5,
    height: 1.33,
  );

  /// 11sp — Navigation labels, tiny tags
  static final TextStyle darkLabelSmall = _base(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.darkTextDisabled,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Light Theme Text Styles
  // ─────────────────────────────────────────────────────────────────────────

  static final TextStyle lightDisplayLarge = darkDisplayLarge.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightDisplayMedium = darkDisplayMedium.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightDisplaySmall = darkDisplaySmall.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightHeadlineLarge = darkHeadlineLarge.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightHeadlineMedium = darkHeadlineMedium.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightHeadlineSmall = darkHeadlineSmall.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightTitleLarge = darkTitleLarge.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightTitleMedium = darkTitleMedium.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightTitleSmall = darkTitleSmall.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightBodyLarge = darkBodyLarge.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightBodyMedium = darkBodyMedium.copyWith(
    color: AppColors.lightTextSecondary,
  );

  static final TextStyle lightBodySmall = darkBodySmall.copyWith(
    color: AppColors.lightTextSecondary,
  );

  static final TextStyle lightLabelLarge = darkLabelLarge.copyWith(
    color: AppColors.lightTextPrimary,
  );

  static final TextStyle lightLabelMedium = darkLabelMedium.copyWith(
    color: AppColors.lightTextSecondary,
  );

  static final TextStyle lightLabelSmall = darkLabelSmall.copyWith(
    color: AppColors.lightTextDisabled,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Accent / Colored Text Styles (theme-agnostic)
  // ─────────────────────────────────────────────────────────────────────────

  static final TextStyle cyanHeadline = darkHeadlineMedium.copyWith(
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
  // TextTheme builders
  // ─────────────────────────────────────────────────────────────────────────

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: darkDisplayLarge,
        displayMedium: darkDisplayMedium,
        displaySmall: darkDisplaySmall,
        headlineLarge: darkHeadlineLarge,
        headlineMedium: darkHeadlineMedium,
        headlineSmall: darkHeadlineSmall,
        titleLarge: darkTitleLarge,
        titleMedium: darkTitleMedium,
        titleSmall: darkTitleSmall,
        bodyLarge: darkBodyLarge,
        bodyMedium: darkBodyMedium,
        bodySmall: darkBodySmall,
        labelLarge: darkLabelLarge,
        labelMedium: darkLabelMedium,
        labelSmall: darkLabelSmall,
      );

  static TextTheme get lightTextTheme => TextTheme(
        displayLarge: lightDisplayLarge,
        displayMedium: lightDisplayMedium,
        displaySmall: lightDisplaySmall,
        headlineLarge: lightHeadlineLarge,
        headlineMedium: lightHeadlineMedium,
        headlineSmall: lightHeadlineSmall,
        titleLarge: lightTitleLarge,
        titleMedium: lightTitleMedium,
        titleSmall: lightTitleSmall,
        bodyLarge: lightBodyLarge,
        bodyMedium: lightBodyMedium,
        bodySmall: lightBodySmall,
        labelLarge: lightLabelLarge,
        labelMedium: lightLabelMedium,
        labelSmall: lightLabelSmall,
      );
}
