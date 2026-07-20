import 'package:flutter/material.dart';

/// Centralized color system for the SecureCity AI Authority Dashboard.
/// Hex values are ported from `mobile/lib/core/theme/app_colors.dart` for
/// brand consistency across the citizen app and the dashboard — these are
/// two separate Flutter packages so the values are re-declared, not shared
/// via import.
abstract final class AppColors {
  // ── Brand / Primary ──────────────────────────────────────────────────
  static const Color primaryDeepBlue = Color(0xFF1A1A2E);
  static const Color primaryNavyBlue = Color(0xFF16213E);
  static const Color primaryRoyalBlue = Color(0xFF0F3460);

  // ── Accent ────────────────────────────────────────────────────────────
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentCyanGlow = Color(0x4000D4FF);

  // ── Emergency & Alert ─────────────────────────────────────────────────
  static const Color emergencyRed = Color(0xFFFF3B3B);
  static const Color emergencyRedDark = Color(0xFFCC2E2E);
  static const Color emergencyRedGlow = Color(0x55FF3B3B);
  static const Color emergencyOrange = Color(0xFFFF6B35);

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color successGreen = Color(0xFF00C853);
  static const Color warningAmber = Color(0xFFFFAB00);
  static const Color infoBlue = Color(0xFF2979FF);

  // ── Dark Surfaces ─────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0A1A);
  static const Color darkSurface = Color(0xFF12122A);
  static const Color darkCard = Color(0xFF1A1A35);
  static const Color darkCardElevated = Color(0xFF222245);
  static const Color darkDivider = Color(0xFF2A2A4A);
  static const Color darkBorder = Color(0xFF2E2E52);

  // ── Text — Dark Theme ─────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextDisabled = Color(0xFF555577);

  // ── Glassmorphism ─────────────────────────────────────────────────────
  static const Color glassWhite10 = Color(0x1AFFFFFF);
  static const Color glassCyan10 = Color(0x1A00D4FF);
  static const Color glassCyan20 = Color(0x3300D4FF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderCyan = Color(0x5500D4FF);

  // ── Chart Palette ─────────────────────────────────────────────────────
  static const Color chartBar1 = accentCyan;
  static const Color chartBar2 = Color(0xFF7C4DFF);
  static const Color chartBar3 = successGreen;
  static const Color chartBar4 = warningAmber;
  static const Color chartBar5 = emergencyRed;

  // ── Utility ───────────────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
}
