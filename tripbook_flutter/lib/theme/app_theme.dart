import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // --- Primary & Brand ---
  static const Color primary = Color(0xFF5B5CFF);
  static const Color primaryRGB = Color(0xFF5B5CFF);
  static const List<Color> brandGradient = [Color(0xFF5B5CFF), Color(0xFF8B5CF6), Color(0xFFD946EF)];
  static const List<Color> brandGradient2 = [Color(0xFF5B5CFF), Color(0xFF8B5CF6)];

  // --- Accent / Additional ---
  static const List<Color> accentGradient = [Color(0xFF8B5CF6), Color(0xFFD946EF)];
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFD946EF);

  // --- Quick Action Gradients ---
  static const List<Color> expenseGradient = [Color(0xFF5B5CFF), Color(0xFF7C3AED)];
  static const List<Color> poolGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> settleGradient = [Color(0xFFF59E0B), Color(0xFFF97316)];
  static const List<Color> statsGradient = [Color(0xFF06B6D4), Color(0xFF3B82F6)];

  // --- Status Colors ---
  static const Color positive = Color(0xFF10B981);
  static const Color positiveLight = Color(0xFF10B981); // rgba(16,185,129,0.1) approx
  static const Color positiveDark = Color(0xFF34D399); // web: #34d399
  static const Color negative = Color(0xFFF43F5E);
  static const Color negativeLight = Color(0xFFF43F5E);
  static const Color negativeDark = Color(0xFFE25252); // web: #fca5a5 approx
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFF59E0B); // rgba(245,158,11,0.1) approx
  static const Color warningDark = Color(0xFFFDE047); // web: #fde047
  static const Color info = Color(0xFF06B6D4);
  static const Color infoLight = Color(0xFF06B6D4); // rgba(6,182,212,0.1) approx

  // --- Light Theme Colors ---
  static const Color bgLight = Color(0xFFF5F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLightMain = Color(0xFF0F172A);
  static const Color textLightMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // --- Dark Theme Colors ---
  static const Color bgDark = Color(0xFF070A12);
  static const Color surfaceDark = Color(0xFF0B1020);
  static const Color elevatedDark = Color(0xFF101729);
  static const Color textDarkMain = Color(0xFFF8FAFC);
  static const Color textDarkMuted = Color(0xFF94A3B8);
  static const Color borderDark = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // --- Glassmorphism ---
  static const Color glassBgLight = Color(0xFF0F172A); // rgba(15,23,42,0.85) approx
  static const Color glassBgDark = Color(0xFF0B1020); // rgba(11,16,32,0.7) approx
  static const double glassBlurSigma = 24.0; // web: var(--glass-blur) = blur(24px)

  // --- Shadows ---
  static const Color shadowSm = Color(0x33000000); // 0 1px 2px 0 rgba(0,0,0,0.3)
  static const Color shadowMd = Color(0x7A000000); // 0 4px 20px -2px rgba(0,0,0,0.5) + 0 2px 6px -2px rgba(0,0,0,0.3)
  static const Color shadowLg = Color(0xAA000000); // 0 10px 30px -4px rgba(0,0,0,0.7) + 0 4px 10px -4px rgba(0,0,0,0.4)
  static const Color shadowSheet = Color(0xA0000000); // 0 -10px 40px -5px rgba(0,0,0,0.6) - bottom nav shadow

  // --- Borders ---
  static const Color borderPrimary = Color(0xFF5B5CFF); // --border-focus
  static const Color borderSubtle = Color(0x0A000000); // rgba(255,255,255,0.04) approx

  // --- Text Colors ---
  static const Color textPrimaryLight = Color(0xFF0F172A); // --text-main light
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // --text-main dark
  static const Color textSecondaryLight = Color(0xFF64748B); // --text-muted light
  static const Color textSecondaryDark = Color(0xFF94A3B8); // --text-muted dark
  static const Color textInverse = Color(0xFF070A12); // --text-inverse dark
  static const Color textLight = Color(0xFF64748B);
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color textMutedDark = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.negative,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.textLightMain, fontWeight: FontWeight.bold, fontSize: 20),
        bodyLarge: TextStyle(color: AppColors.textLightMain, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textLightMuted, fontSize: 14),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.negative,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.elevatedDark,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.textDarkMain, fontWeight: FontWeight.bold, fontSize: 20),
        bodyLarge: TextStyle(color: AppColors.textDarkMain, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
      ),
    );
  }
}

// Glassmorphic Card Container Widget - Matching web card styles
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final List<Color>? borderGradients;
  final Color? bgColor;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0, // web: --radius-lg = 24px
    this.borderGradients,
    this.bgColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppColors.glassBlurSigma, sigmaY: AppColors.glassBlurSigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: bgColor ?? (isDark ? AppColors.glassBgDark : AppColors.glassBgLight),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05),
              width: 1.0,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}