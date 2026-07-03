import 'package:flutter/material.dart';

abstract class AppColors {
  // ─── Brand ──────────────────────
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFFEEF2FF);

  // ─── Semantic ───────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  // ─── Light Mode Surfaces ────────
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF5F5F5);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textDisabledLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);

  // ─── Dark Mode Surfaces ─────────
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceSecondaryDark = Color(0xFF293548);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textDisabledDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF263244);
}
