import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Animation duration constants — mirrors
/// `mobile/lib/core/theme/app_theme.dart`'s `AppDurations` exactly, so
/// timing is consistent across both apps.
abstract final class AppDurations {
  static const Duration instant = Duration.zero;
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
  static const Duration slowest = Duration(milliseconds: 1000);
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration pulseAnimation = Duration(milliseconds: 1200);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
}

/// Glassmorphism decoration helpers, matching the visual language of
/// `mobile/lib/core/theme/app_theme.dart`'s `GlassDecoration`.
abstract final class GlassDecoration {
  static BoxDecoration card({
    Color? borderColor,
    Color? backgroundColor,
    double borderRadius = 16,
  }) =>
      BoxDecoration(
        color: backgroundColor ?? AppColors.glassWhite10,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.glassBorderLight),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.3), blurRadius: 20),
        ],
      );

  static BoxDecoration surfaceCard({double borderRadius = 16}) => BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.2), blurRadius: 12),
        ],
      );

  static BoxDecoration cyanCard({double borderRadius = 16}) => card(
        borderColor: AppColors.glassBorderCyan,
        backgroundColor: AppColors.glassCyan10,
        borderRadius: borderRadius,
      );

  static BoxDecoration emergencyCard({double borderRadius = 16}) => card(
        borderColor: AppColors.emergencyRedGlow,
        backgroundColor: AppColors.emergencyRedGlow,
        borderRadius: borderRadius,
      );
}

abstract final class AppTheme {
  static ThemeData get darkTheme {
    final fontFamily = GoogleFonts.inter().fontFamily;

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accentCyan,
      onPrimary: AppColors.primaryDeepBlue,
      primaryContainer: AppColors.primaryRoyalBlue,
      onPrimaryContainer: AppColors.accentCyan,
      secondary: AppColors.primaryRoyalBlue,
      onSecondary: AppColors.darkTextPrimary,
      secondaryContainer: AppColors.primaryNavyBlue,
      onSecondaryContainer: AppColors.darkTextPrimary,
      tertiary: AppColors.successGreen,
      onTertiary: AppColors.darkBackground,
      tertiaryContainer: AppColors.darkCardElevated,
      onTertiaryContainer: AppColors.darkTextPrimary,
      error: AppColors.emergencyRed,
      onError: AppColors.white,
      errorContainer: AppColors.emergencyRedDark,
      onErrorContainer: AppColors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkCardElevated,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkDivider,
      shadow: AppColors.black,
      scrim: Color(0xCC0A0A1A),
      inverseSurface: AppColors.white,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.primaryRoyalBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTypography.textTheme,
      fontFamily: fontFamily,
      brightness: Brightness.dark,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentCyan,
          foregroundColor: AppColors.primaryDeepBlue,
          disabledBackgroundColor: AppColors.darkCardElevated,
          disabledForegroundColor: AppColors.darkTextDisabled,
          elevation: 0,
          shadowColor: AppColors.accentCyanGlow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          side: const BorderSide(color: AppColors.accentCyan, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          textStyle: AppTypography.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
        ),
        hintStyle: AppTypography.bodyMedium,
        labelStyle: AppTypography.bodyMedium,
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.emergencyRed),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.darkDivider, thickness: 1),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.darkCardElevated),
        dataRowColor: WidgetStateProperty.all(AppColors.darkCard),
        dividerThickness: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCardElevated,
        selectedColor: AppColors.glassCyan20,
        disabledColor: AppColors.darkCard,
        labelStyle: AppTypography.labelMedium,
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.transparent,
        elevation: 24,
        shadowColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
      ),

      listTileTheme: ListTileThemeData(
        tileColor: AppColors.transparent,
        selectedTileColor: AppColors.glassCyan10,
        iconColor: AppColors.darkTextSecondary,
        textColor: AppColors.darkTextPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCardElevated,
        contentTextStyle: AppTypography.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentCyan,
        linearTrackColor: AppColors.darkCardElevated,
        circularTrackColor: AppColors.darkCardElevated,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accentCyan;
          return AppColors.darkTextDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.glassCyan20;
          return AppColors.darkCardElevated;
        }),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: AppColors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accentCyan,
        unselectedLabelColor: AppColors.darkTextSecondary,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelMedium,
        indicatorColor: AppColors.accentCyan,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.darkDivider,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkCardElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        textStyle: AppTypography.bodySmall,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
