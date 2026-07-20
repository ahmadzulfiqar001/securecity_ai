import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Animation duration constants used throughout the app.
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

/// Glassmorphism decoration helpers.
abstract final class GlassDecoration {
  static BoxDecoration card({
    Color? borderColor,
    Color? backgroundColor,
    double borderRadius = 16,
    double borderWidth = 1,
  }) =>
      BoxDecoration(
        color: backgroundColor ?? AppColors.glassWhite10,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorderLight,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
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

  static BoxDecoration surfaceCard({double borderRadius = 16}) => BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

/// Main theme provider for SecureCity AI.
abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // Dark Theme
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
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
      tertiaryContainer: AppColors.successGreenDim,
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
      scrim: AppColors.darkOverlay,
      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.lightTextPrimary,
      inversePrimary: AppColors.primaryRoyalBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTypography.darkTextTheme,
      fontFamily: AppTypography.darkTextTheme.bodyMedium?.fontFamily,
      brightness: Brightness.dark,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.navBarBackground,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTypography.darkTitleLarge,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.accentCyan, size: 24),
      ),

      // ── Bottom Navigation Bar ────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navBarSelectedItem,
        unselectedItemColor: AppColors.navBarUnselectedItem,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        indicatorColor: AppColors.navBarIndicator,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navBarSelectedItem, size: 24);
          }
          return const IconThemeData(color: AppColors.navBarUnselectedItem, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.darkLabelSmall.copyWith(
              color: AppColors.navBarSelectedItem,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.darkLabelSmall;
        }),
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      // ── Elevated Buttons ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentCyan,
          foregroundColor: AppColors.primaryDeepBlue,
          disabledBackgroundColor: AppColors.darkCardElevated,
          disabledForegroundColor: AppColors.darkTextDisabled,
          elevation: 0,
          shadowColor: AppColors.accentCyanGlow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTypography.darkLabelLarge.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Outlined Buttons ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          side: const BorderSide(color: AppColors.accentCyan, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTypography.darkLabelLarge.copyWith(fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // ── Text Buttons ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentCyan,
          textStyle: AppTypography.darkLabelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // ── Input / TextField ─────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emergencyRed, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider, width: 1),
        ),
        hintStyle: AppTypography.darkBodyMedium.copyWith(
          color: AppColors.darkTextHint,
        ),
        labelStyle: AppTypography.darkBodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        errorStyle: AppTypography.darkBodySmall.copyWith(
          color: AppColors.emergencyRed,
        ),
        prefixIconColor: AppColors.darkTextSecondary,
        suffixIconColor: AppColors.darkTextSecondary,
        floatingLabelStyle: AppTypography.darkLabelMedium.copyWith(
          color: AppColors.accentCyan,
        ),
      ),

      // ── Dividers ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCardElevated,
        selectedColor: AppColors.glassCyan20,
        disabledColor: AppColors.darkCard,
        labelStyle: AppTypography.darkLabelMedium,
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Dialogs ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: AppColors.transparent,
        elevation: 24,
        shadowColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        titleTextStyle: AppTypography.darkHeadlineSmall,
        contentTextStyle: AppTypography.darkBodyMedium,
      ),

      // ── BottomSheet ──────────────────────────────────────────────────────
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

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.transparent,
        selectedTileColor: AppColors.glassCyan10,
        iconColor: AppColors.darkTextSecondary,
        textColor: AppColors.darkTextPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCardElevated,
        contentTextStyle: AppTypography.darkBodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Progress Indicators ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentCyan,
        linearTrackColor: AppColors.darkCardElevated,
        circularTrackColor: AppColors.darkCardElevated,
      ),

      // ── Switch ───────────────────────────────────────────────────────────
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

      // ── Floating Action Button ───────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emergencyRed,
        foregroundColor: AppColors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),

      // ── Tab Bar ──────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accentCyan,
        unselectedLabelColor: AppColors.darkTextSecondary,
        labelStyle: AppTypography.darkLabelLarge,
        unselectedLabelStyle: AppTypography.darkLabelMedium,
        indicatorColor: AppColors.accentCyan,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.darkDivider,
      ),

      // ── Tooltip ──────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.darkCardElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        textStyle: AppTypography.darkBodySmall,
      ),

      // ── Page Transitions ─────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Light Theme
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryRoyalBlue,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.lightCardElevated,
      onPrimaryContainer: AppColors.primaryRoyalBlue,
      secondary: AppColors.primaryNavyBlue,
      onSecondary: AppColors.white,
      secondaryContainer: AppColors.lightCard,
      onSecondaryContainer: AppColors.primaryNavyBlue,
      tertiary: AppColors.successGreenDim,
      onTertiary: AppColors.white,
      tertiaryContainer: Color(0xFFE8F5E9),
      onTertiaryContainer: AppColors.successGreenDim,
      error: AppColors.emergencyRedDark,
      onError: AppColors.white,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: AppColors.emergencyRedDark,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightCardElevated,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightDivider,
      shadow: AppColors.black,
      scrim: Color(0x990A0A1A),
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.darkTextPrimary,
      inversePrimary: AppColors.accentCyan,
    );

    return darkTheme.copyWith(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: AppTypography.lightTextTheme,
      appBarTheme: darkTheme.appBarTheme.copyWith(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.lightSurface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.lightTitleLarge,
      ),
      cardTheme: darkTheme.cardTheme.copyWith(
        color: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: darkTheme.inputDecorationTheme.copyWith(
        fillColor: AppColors.lightCardElevated,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        hintStyle: AppTypography.lightBodyMedium.copyWith(
          color: AppColors.lightTextHint,
        ),
        labelStyle: AppTypography.lightBodyMedium.copyWith(
          color: AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
