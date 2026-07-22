import 'package:flutter/material.dart';

/// Centralized color system for SecureCity AI.
/// All colors follow the dark-first, glassmorphism-inspired design language.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────────
  // Brand / Primary Palette
  // ─────────────────────────────────────────────────────────────────────────
  static const Color primaryDeepBlue = Color(0xFF1A1A2E);
  static const Color primaryNavyBlue = Color(0xFF16213E);
  static const Color primaryRoyalBlue = Color(0xFF0F3460);
  static const Color primaryAccent = Color(0xFF1B4F8A);

  // ─────────────────────────────────────────────────────────────────────────
  // Accent / Highlight Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentCyanDim = Color(0xFF0099BB);
  static const Color accentCyanGlow = Color(0x4000D4FF);

  // ─────────────────────────────────────────────────────────────────────────
  // Emergency & Alert Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color emergencyRed = Color(0xFFFF3B3B);
  static const Color emergencyRedDark = Color(0xFFCC2E2E);
  static const Color emergencyRedGlow = Color(0x55FF3B3B);
  static const Color emergencyOrange = Color(0xFFFF6B35);

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color successGreen = Color(0xFF00C853);
  static const Color successGreenDim = Color(0xFF009C41);
  static const Color successGreenGlow = Color(0x4000C853);

  static const Color warningAmber = Color(0xFFFFAB00);
  static const Color warningAmberDim = Color(0xFFCC8800);
  static const Color warningAmberGlow = Color(0x44FFAB00);

  static const Color infoBlue = Color(0xFF2979FF);
  static const Color infoBlueDim = Color(0xFF1565C0);

  // ─────────────────────────────────────────────────────────────────────────
  // Dark Theme Surface Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0A1A);
  static const Color darkSurface = Color(0xFF12122A);
  static const Color darkCard = Color(0xFF1A1A35);
  static const Color darkCardElevated = Color(0xFF222245);
  static const Color darkOverlay = Color(0xCC0A0A1A);
  static const Color darkDivider = Color(0xFF2A2A4A);
  static const Color darkBorder = Color(0xFF2E2E52);

  // ─────────────────────────────────────────────────────────────────────────
  // Light Theme Surface Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F2FF);
  static const Color lightCardElevated = Color(0xFFE8EBFF);
  static const Color lightOverlay = Color(0x99FFFFFF);
  static const Color lightDivider = Color(0xFFDDE0FF);
  static const Color lightBorder = Color(0xFFCDD0F0);

  // ─────────────────────────────────────────────────────────────────────────
  // Text Colors - Dark Theme
  // ─────────────────────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextDisabled = Color(0xFF555577);
  static const Color darkTextHint = Color(0xFF666688);

  // ─────────────────────────────────────────────────────────────────────────
  // Text Colors - Light Theme
  // ─────────────────────────────────────────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF0A0A1A);
  static const Color lightTextSecondary = Color(0xFF444466);
  static const Color lightTextDisabled = Color(0xFF9999BB);
  static const Color lightTextHint = Color(0xFF8888AA);

  // ─────────────────────────────────────────────────────────────────────────
  // Glassmorphism Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color glassWhite10 = Color(0x1AFFFFFF);
  static const Color glassWhite15 = Color(0x26FFFFFF);
  static const Color glassWhite20 = Color(0x33FFFFFF);
  static const Color glassWhite30 = Color(0x4DFFFFFF);
  static const Color glassWhite50 = Color(0x80FFFFFF);

  static const Color glassCyan10 = Color(0x1A00D4FF);
  static const Color glassCyan20 = Color(0x3300D4FF);
  static const Color glassBlue10 = Color(0x1A0F3460);
  static const Color glassBlue20 = Color(0x330F3460);

  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderCyan = Color(0x5500D4FF);

  // ─────────────────────────────────────────────────────────────────────────
  // Gradient Definitions
  // ─────────────────────────────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    primaryDeepBlue,
    primaryNavyBlue,
    primaryRoyalBlue,
  ];

  static const List<Color> splashGradient = [
    Color(0xFF050510),
    Color(0xFF0A0A1A),
    Color(0xFF0D0D28),
  ];

  static const List<Color> accentGradient = [
    accentCyan,
    Color(0xFF0055FF),
  ];

  static const List<Color> emergencyGradient = [
    emergencyRed,
    Color(0xFFAA0000),
  ];

  static const List<Color> successGradient = [
    Color(0xFF00E676),
    successGreen,
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Heatmap / Safety Zone Colors (safe → caution → danger)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color heatmapSafe = Color(0xFF00E676);
  static const Color heatmapMostlySafe = Color(0xFF69F0AE);
  static const Color heatmapCaution = Color(0xFFFFD740);
  static const Color heatmapModerate = Color(0xFFFF9100);
  static const Color heatmapDanger = Color(0xFFFF3D00);
  static const Color heatmapHighDanger = Color(0xFFFF1744);
  static const Color heatmapCritical = Color(0xFFD50000);

  static const List<Color> heatmapGradient = [
    heatmapSafe,
    heatmapMostlySafe,
    heatmapCaution,
    heatmapModerate,
    heatmapDanger,
    heatmapHighDanger,
    heatmapCritical,
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Chart Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color chartBar1 = accentCyan;
  static const Color chartBar2 = Color(0xFF7C4DFF);
  static const Color chartBar3 = successGreen;
  static const Color chartBar4 = warningAmber;
  static const Color chartBar5 = emergencyRed;

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation Bar Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color navBarBackground = Color(0xFF0D0D22);
  static const Color navBarSelectedItem = accentCyan;
  static const Color navBarUnselectedItem = Color(0xFF666688);
  static const Color navBarIndicator = Color(0x2200D4FF);
  static const Color sosFabColor = emergencyRed;
  static const Color sosFabGlow = emergencyRedGlow;

  // ─────────────────────────────────────────────────────────────────────────
  // Map Marker Colors
  // ─────────────────────────────────────────────────────────────────────────
  static const Color markerPolice = Color(0xFF1565C0);
  static const Color markerHospital = Color(0xFFD32F2F);
  static const Color markerFireStation = Color(0xFFE64A19);
  static const Color markerIncident = emergencyOrange;
  static const Color markerUser = accentCyan;
  static const Color markerSafeZone = successGreen;

  // ─────────────────────────────────────────────────────────────────────────
  // Transparent / Utility
  // ─────────────────────────────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}
