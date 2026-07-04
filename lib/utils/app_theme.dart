import 'package:flutter/material.dart';

class AppColors {
  // Core Backgrounds
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF2F2F0);
  static const Color surfaceMuted = Color(0xFFF5F5F3);

  // Primary (near-black)
  static const Color primary = Color(0xFF0C0C0F);
  static const Color primaryLight = Color(0xFF1C1C26);

  // Accent (electric indigo — single vibrant tone)
  static const Color accent = Color(0xFF5B5FEF);
  static const Color accentLight = Color(0xFF7B7FF5);
  static const Color accentDark = Color(0xFF4146D0);
  static const Color accentSurface = Color(0xFFEEEFFC);

  // Accent amber (star ratings, highlights)
  static const Color amber = Color(0xFFF59E0B);

  // Status
  static const Color success = Color(0xFF16A34A);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSurface = Color(0xFFDCEFFE);

  // Text
  static const Color textPrimary = Color(0xFF0C0C0F);
  static const Color textSecondary = Color(0xFF6B6B7A);
  static const Color textTertiary = Color(0xFFA1A1B0);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFC4C4CF);

  // Border & Divider
  static const Color border = Color(0xFFE5E5E3);
  static const Color borderStrong = Color(0xFFD0D0CE);
  static const Color divider = Color(0xFFF0F0EE);

  // Semantic
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color inactiveGray = Color(0xFFA1A1B0);
  static const Color lowStockOrange = Color(0xFFD97706);
  static const Color criticalStockRed = Color(0xFFDC2626);

  // Minimal gradients — use sparingly, only for hero/CTA elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy aliases kept for compatibility
  static const Color gradientPurple = Color(0xFF5B5FEF);
  static const Color gradientPurpleDark = Color(0xFF4146D0);
  static const Color gradientBlue = Color(0xFF2563EB);
  static const Color gradientBlueDark = Color(0xFF1D4ED8);
  static const Color gradientOrange = Color(0xFFD97706);
  static const Color gradientOrangeDark = Color(0xFFB45309);

  static const LinearGradient purpleGradient = accentGradient;
  static const LinearGradient blueGradient = LinearGradient(
    colors: [info, Color(0xFF1D4ED8)],
  );
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [warning, Color(0xFFB45309)],
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF15803D)],
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, error],
  );
  static const LinearGradient accentGradientCompat = accentGradient;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
}

class AppRadius {
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.textTertiary,
  );
}

class AppShadows {
  static List<BoxShadow> small = [
    BoxShadow(
      color: const Color(0xFF0C0C0F).withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: const Color(0xFF0C0C0F).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> large = [
    BoxShadow(
      color: const Color(0xFF0C0C0F).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> colored(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
