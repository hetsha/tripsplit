import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  // --- TripSplit Brand & Royal Purple Gradients ---
  static const Color primary = Color(0xFF6C38FF);
  static const Color primaryRGB = Color(0xFF6C38FF);
  static const Color primaryDark = Color(0xFF5B2DE8);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFA855F7);
  static const Color brandLavender = Color(0xFFF3E8FF);
  static const Color brandLavenderLight = Color(0xFFF8F5FE);

  // Gradient for primary buttons and banners
  static const List<Color> brandGradient = [
    Color(0xFF5B3EE8),
    Color(0xFF7A42F3),
    Color(0xFF8E3CF8),
  ];
  static const List<Color> brandGradient2 = [
    Color(0xFF5B3EE8),
    Color(0xFF7E42F5),
  ];
  static const List<Color> accentGradient = [Color(0xFF8B5CF6), Color(0xFFD946EF)];
  static const List<Color> splashGradient = [
    Color(0xFF070926),
    Color(0xFF0F1138),
    Color(0xFF1D1248),
  ];

  // --- Status Colors ---
  static const Color positive = Color(0xFF10B981);
  static const Color positiveLight = Color(0xFF10B981);
  static const Color positiveDark = Color(0xFF34D399);
  static const Color positiveBg = Color(0xFFECFDF5);
  static const Color positiveText = Color(0xFF059669);

  static const Color negative = Color(0xFFEF4444);
  static const Color negativeLight = Color(0xFFEF4444);
  static const Color negativeDark = Color(0xFFE25252);
  static const Color negativeBg = Color(0xFFFEF2F2);
  static const Color negativeText = Color(0xFFDC2626);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFDE047);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFFD97706);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF06B6D4);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoText = Color(0xFF2563EB);

  // --- Quick Action Gradients ---
  static const List<Color> expenseGradient = [Color(0xFF6C38FF), Color(0xFF8B5CF6)];
  static const List<Color> membersGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
  static const List<Color> settleGradient = [Color(0xFFEC4899), Color(0xFFF43F5E)];
  static const List<Color> galleryGradient = [Color(0xFF10B981), Color(0xFF34D399)];
  static const List<Color> poolGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> statsGradient = [Color(0xFF06B6D4), Color(0xFF3B82F6)];

  // --- Light Theme Colors ---
  static const Color bgLight = Color(0xFFF8F9FE);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLightMain = Color(0xFF1E1B4B);
  static const Color textLightMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFEBE8F8);
  static const Color inputBgLight = Color(0xFFF8FAFC);

  // --- Dark Theme Colors ---
  static const Color bgDark = Color(0xFF070A12);
  static const Color surfaceDark = Color(0xFF0B1020);
  static const Color elevatedDark = Color(0xFF101729);
  static const Color textDarkMain = Color(0xFFF8FAFC);
  static const Color textDarkMuted = Color(0xFF94A3B8);
  static const Color borderDark = Color(0x14FFFFFF);

  // --- Glassmorphism ---
  static const Color glassBgLight = Color(0xFF0F172A);
  static const Color glassBgDark = Color(0xFF0B1020);
  static const double glassBlurSigma = 16.0;

  // --- Shadows ---
  static const Color shadowSm = Color(0x33000000);
  static const Color shadowMd = Color(0x7A000000);
  static const Color shadowLg = Color(0xAA000000);
  static const Color shadowSheet = Color(0xA0000000);

  // --- Borders ---
  static const Color borderPrimary = Color(0xFF6C38FF);
  static const Color borderSubtle = Color(0x0A000000);

  // --- Text Colors ---
  static const Color textPrimaryLight = Color(0xFF1E1B4B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFF070A12);
  static const Color textLight = Color(0xFF64748B);
  static const Color textMainLight = Color(0xFF1E1B4B);
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
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textLightMain),
        titleTextStyle: TextStyle(
          color: AppColors.textLightMain,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.textLightMain,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: AppColors.textLightMain,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textLightMain,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textLightMuted,
          fontSize: 13,
        ),
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
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textDarkMain),
        titleTextStyle: TextStyle(
          color: AppColors.textDarkMain,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.elevatedDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.textDarkMain,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: AppColors.textDarkMain,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textDarkMain,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textDarkMuted,
          fontSize: 13,
        ),
      ),
    );
  }
}

// Glassmorphic Card Container Widget
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
    this.borderRadius = 24.0,
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
          ),
          child: child,
        ),
      ),
    );
  }
}