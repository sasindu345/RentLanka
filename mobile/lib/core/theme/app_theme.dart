import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

class AppTheme {
  // Retain the old colors as backward-compatibility aliases during migration
  // to avoid breaking any references until the color audit phase is complete.
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryHover;
  static const Color accent = AppColors.primary;
  static const Color background = AppColors.backgroundLight;
  static const Color card = AppColors.surfaceLight;
  static const Color muted = AppColors.textSecondaryLight;

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        background: AppColors.backgroundLight,
        onBackground: AppColors.textPrimaryLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceVariant: AppColors.surfaceSecondaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      dividerColor: AppColors.dividerLight,
      
      // Typography Scale
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 36, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5, color: AppColors.textPrimaryLight),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3, letterSpacing: -0.3, color: AppColors.textPrimaryLight),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.2, color: AppColors.textPrimaryLight),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimaryLight),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.textPrimaryLight),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textPrimaryLight),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.1, color: AppColors.textSecondaryLight),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.2, color: AppColors.textSecondaryLight),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight, size: 22),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondaryLight, size: 24);
        }),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textDisabledLight, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
      ),

      // Buttons Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        modalBackgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.sheet),
            topRight: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryHover,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textPrimaryDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceVariant: AppColors.surfaceSecondaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: AppColors.borderDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: AppColors.dividerDark,

      // Typography Scale
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 36, fontWeight: FontWeight.bold, height: 1.2, letterSpacing: -0.5, color: AppColors.textPrimaryDark),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3, letterSpacing: -0.3, color: AppColors.textPrimaryDark),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.2, color: AppColors.textPrimaryDark),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimaryDark),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: AppColors.textPrimaryDark),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textPrimaryDark),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 1.4, letterSpacing: 0.1, color: AppColors.textSecondaryDark),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.2, color: AppColors.textSecondaryDark),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark, size: 22),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.surfaceSecondaryDark,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondaryDark, size: 24);
        }),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textDisabledDark, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
      ),

      // Buttons Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.sheet),
            topRight: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
    );
  }
}
