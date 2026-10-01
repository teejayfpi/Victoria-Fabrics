import 'package:flutter/material.dart';

/// Victoria Fabrics Enterprise Color System
///
/// A premium palette built around deep emerald (trust) and warm gold
/// (premium), with a terracotta heritage tone that suits fabric and textile
/// retail. Includes gradient, glassmorphism and elevation tokens so screens
/// stay visually consistent.
class AppColors {
  AppColors._();

  // ===========================================================================
  // PRIMARY PALETTE - Deep Emerald
  // ===========================================================================
  static const Color primary = Color(0xFF0A6847);
  static const Color primaryDark = Color(0xFF054832);
  static const Color primaryLight = Color(0xFF12A869);
  static const Color primarySurface = Color(0xFF0E8055);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12A869), Color(0xFF0A6847), Color(0xFF054832)],
  );

  static const LinearGradient primaryGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1ED89A), Color(0xFF12A869), Color(0xFF0A6847)],
  );

  // ===========================================================================
  // ACCENT PALETTE - Warm Gold
  // ===========================================================================
  static const Color accent = Color(0xFFFFB800);
  static const Color accentDark = Color(0xFFE09400);
  static const Color accentLight = Color(0xFFFFD54F);
  static const Color accentSurface = Color(0xFFFFF3E0);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD54F), Color(0xFFFFB800), Color(0xFFE09400)],
  );

  // ===========================================================================
  // TERRACOTTA - Warm Earthy Tone (Textile Heritage)
  // ===========================================================================
  static const Color terracotta = Color(0xFFCE6D3A);
  static const Color terracottaLight = Color(0xFFE8925A);
  static const Color terracottaSurface = Color(0xFFFFF4EC);

  // ===========================================================================
  // BACKGROUND SYSTEM
  // ===========================================================================
  static const Color background = Color(0xFFF8FAF9);
  static const Color backgroundSecondary = Color(0xFFF0F4F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceOverlay = Color(0xFFF5F7F6);

  // ===========================================================================
  // GLASS & FROSTED EFFECTS
  // ===========================================================================
  static const Color glassWhite = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x30FFFFFF);
  static const Color glassShadow = Color(0x0A000000);

  // ===========================================================================
  // TEXT HIERARCHY
  // ===========================================================================
  static const Color textPrimary = Color(0xFF0D1F1A);
  static const Color textSecondary = Color(0xFF4A5C56);
  static const Color textMuted = Color(0xFF8A9E98);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF1A1400);

  // ===========================================================================
  // SEMANTIC COLORS
  // ===========================================================================
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFA82835);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFE8FDF5);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color warningDark = Color(0xFFD97706);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoDark = Color(0xFF2563EB);

  // ===========================================================================
  // BORDER & DIVIDER SYSTEM
  // ===========================================================================
  static const Color border = Color(0xFFE2E8E4);
  static const Color borderLight = Color(0xFFF0F4F3);
  static const Color divider = Color(0xFFE8EDEA);
  static const Color dividerLight = Color(0xFFF5F7F6);

  // ===========================================================================
  // SHADOW SYSTEM
  // ===========================================================================
  static const Color shadowXs = Color(0x0D000000);
  static const Color shadowSm = Color(0x14000000);
  static const Color shadowMd = Color(0x1F000000);
  static const Color shadowLg = Color(0x28000000);
  static const Color shadowXl = Color(0x33000000);

  static const Color shadowPrimary = Color(0x200A6847);
  static const Color shadowAccent = Color(0x30FFB800);
  static const Color shadowGlass = Color(0x1AFFFFFF);

  // ===========================================================================
  // INPUT & FORM COLORS
  // ===========================================================================
  static const Color inputBackground = Color(0xFFF5F7F6);
  static const Color inputBorder = Color(0xFFE2E8E4);
  static const Color inputFocus = Color(0xFF0A6847);
  static const Color inputDisabled = Color(0xFFF0F4F3);

  // ===========================================================================
  // ORDER STATUS COLORS
  // ===========================================================================
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFFF8E1);
  static const Color statusProcessing = Color(0xFF3B82F6);
  static const Color statusProcessingBg = Color(0xFFEFF6FF);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusDeliveredBg = Color(0xFFE8FDF5);
  static const Color statusCancelled = Color(0xFFDC3545);
  static const Color statusCancelledBg = Color(0xFFFFEBEE);

  // ===========================================================================
  // SHIMMER / SKELETON LOADING
  // ===========================================================================
  static const Color shimmerBase = Color(0xFFE8EDEA);
  static const Color shimmerHighlight = Color(0xFFF5F7F6);

  // ===========================================================================
  // PREMIUM GRADIENTS
  // ===========================================================================
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12A869), Color(0xFF0A6847), Color(0xFF054832)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xB3FFFFFF), Color(0x80FFFFFF), Color(0xB3FFFFFF)],
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x99000000)],
  );

  /// Scrim used over hero photography so overlaid text stays readable.
  static const LinearGradient splashScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x33000000),
      Color(0x1A000000),
      Color(0xCC054832),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ===========================================================================
  // ELEVATION
  // ===========================================================================
  static List<BoxShadow> cardShadow([int level = 1]) {
    switch (level) {
      case 0:
        return const [
          BoxShadow(color: shadowXs, blurRadius: 4, offset: Offset(0, 1)),
        ];
      case 1:
        return const [
          BoxShadow(color: shadowSm, blurRadius: 8, offset: Offset(0, 2)),
          BoxShadow(color: shadowXs, blurRadius: 4, offset: Offset(0, 1)),
        ];
      case 2:
        return const [
          BoxShadow(color: shadowMd, blurRadius: 16, offset: Offset(0, 4)),
          BoxShadow(color: shadowSm, blurRadius: 8, offset: Offset(0, 2)),
        ];
      case 3:
        return const [
          BoxShadow(color: shadowLg, blurRadius: 24, offset: Offset(0, 8)),
          BoxShadow(color: shadowMd, blurRadius: 12, offset: Offset(0, 4)),
        ];
      case 4:
      default:
        return const [
          BoxShadow(color: shadowXl, blurRadius: 32, offset: Offset(0, 12)),
          BoxShadow(color: shadowLg, blurRadius: 16, offset: Offset(0, 6)),
        ];
    }
  }

  static List<BoxShadow> primaryShadow([double opacity = 0.15]) {
    return [
      BoxShadow(
        color: primary.withOpacity(opacity),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primary.withOpacity(opacity * 0.5),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> accentShadow([double opacity = 0.2]) {
    return [
      BoxShadow(
        color: accent.withOpacity(opacity),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: accent.withOpacity(opacity * 0.5),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static BoxDecoration glassDecoration({
    double borderRadius = 20,
    double opacity = 0.8,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glassBorder, width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: shadowGlass,
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}
