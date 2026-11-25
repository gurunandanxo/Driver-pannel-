import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CityRideTheme {
  // Brand Colors (Matching City-Ride Theme)
  static const Color primaryGreen = Color(0xFF05684B); // Deep Forest Emerald
  static const Color primaryGreenDark = Color(0xFF004D36);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color lightGreenChip = Color(0xFFD2F4EB);

  // Background & Surfaces
  static const Color scaffoldBg = Color(0xFFF6F8FA); // Clean ultra-light neutral
  static const Color cardBg = Colors.white;
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardBgDark = Color(0xFF1E293B);

  // Typography Color Pairing
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Status & Alert Colors (Purposeful, Differentiated)
  static const Color successColor = Color(0xFF10B981); // Emerald Green for Verified/Passed
  static const Color warningColor = Color(0xFFF59E0B); // Amber for Incidents/Warnings
  static const Color errorColor = Color(0xFFDC2626);   // Red for SOS/Emergency (Highest visual urgency)
  static const Color infoColor = Color(0xFF0EA5E9);    // Cool Blue for Active/In-Progress
  static const Color neutralAdminColor = Color(0xFF64748B); // Gray-Blue for Admin/Depot
  static const Color offlineColor = Color(0xFF64748B);

  // Intentional Surface Tint Tokens per Module Category
  // 1. Shift Summary Module (Faint Cool Blue-Teal Wash for Active State)
  static const Color shiftCardBg = Color(0xFFF0F9FF);
  static const Color shiftCardBorder = Color(0xFFBAE6FD);
  static const Color shiftAccent = Color(0xFF0284C7);
  static const Color shiftBadgeBg = Color(0xFFE0F2FE);
  static const Color shiftBadgeText = Color(0xFF0369A1);

  // 2. Vehicle Status Module (Faint Green Tint when Verified, Neutral when Pending)
  static const Color vehicleVerifiedBg = Color(0xFFF0FDF4);
  static const Color vehicleVerifiedBorder = Color(0xFFDCFCE7);
  static const Color vehiclePendingBg = Color(0xFFF8FAFC);
  static const Color vehiclePendingBorder = Color(0xFFE2E8F0);
  static const Color vehicleAccent = Color(0xFF05684B);
  static const Color vehicleHeaderBg = Color(0xFF065F46);
  static const Color vehicleBorder = Color(0xFF05684B);
  static const Color vehicleIconBg = Color(0xFFD1FAE5);
  static const Color vehicleBg = Color(0xFFECFDF5);

  // 3. Safety Check Module (Faint Emerald when Passed, Warm Amber when Pending)
  static const Color safetyPassedBg = Color(0xFFF0FDF4);
  static const Color safetyPassedBorder = Color(0xFFBBF7D0);
  static const Color safetyPendingBg = Color(0xFFFFFBEB);
  static const Color safetyPendingBorder = Color(0xFFFDE68A);
  static const Color safetyLockedBg = Color(0xFFF8FAFC);
  static const Color safetyLockedBorder = Color(0xFFE2E8F0);
  static const Color safetyBg = Color(0xFFFEF9EF);
  static const Color safetyHeaderBg = Color(0xFF8D5B18);
  static const Color safetyHeaderDoneBg = Color(0xFF047857);
  static const Color safetyBorder = Color(0xFFD4A359);
  static const Color safetyAccent = Color(0xFFB88234);
  static const Color safetyIconBg = Color(0xFFFBF2E0);
  static const Color inspectionPendingBg = Color(0xFFFEF9EF);
  static const Color inspectionPendingBorder = Color(0xFFF1D7A8);
  static const Color inspectionPendingAccent = Color(0xFFB88234);
  static const Color inspectionPendingText = Color(0xFF784910);
  static const Color inspectionDoneBg = Color(0xFFF0FDF4);
  static const Color inspectionDoneBorder = Color(0xFFBBF7D0);
  static const Color inspectionDoneAccent = Color(0xFF10B981);
  static const Color inspectionDoneText = Color(0xFF166534);

  // Neutral Slate Typography & System Tokens
  static const Color darkSlate = Color(0xFF1F2937); // Near-black for enterprise headings
  static const Color workflowBg = Color(0xFFF0FDFA);
  static const Color workflowHeaderBg = Color(0xFF0F766E);
  static const Color workflowBorder = Color(0xFF0D9488);
  static const Color workflowAccent = Color(0xFF0D9488);
  static const Color workflowIconBg = Color(0xFFCCFBF1);

  // Harmonized Inspection Problem / Unchecked Chip Colors (Warm Terracotta / Sandstone Tone)
  static const Color safetyPillWarningBg = Color(0xFFFFF7ED);
  static const Color safetyPillWarningBorder = Color(0xFFF4D6B5);
  static const Color safetyPillWarningText = Color(0xFFA1551A);
  static const Color safetyPillWarningIcon = Color(0xFFB45309);
  static const Color defectWarningBg = Color(0xFFFDF2F1);
  static const Color defectWarningBorder = Color(0xFFF5C6C3);
  static const Color defectWarningText = Color(0xFFBE3A34);

  // 4. Route Module (Dark Green / Forest Emerald #064E3B matching brand palette)
  static const Color routeBg = Color(0xFFF0FDF4);
  static const Color routeHeaderBg = Color(0xFF064E3B);
  static const Color routeBorder = Color(0xFF059669);
  static const Color routeAccent = Color(0xFF059669);
  static const Color routeIconBg = Color(0xFFD1FAE5);
  static const Color routeText = Color(0xFF064E3B);

  // 5. Ready to Start Module (High-Contrast Emerald Pulse)
  static const Color readyBg = Color(0xFFECFDF5);
  static const Color readyHeaderBg = Color(0xFF065F46);
  static const Color readyBorder = Color(0xFF059669);
  static const Color readyAccent = Color(0xFF059669);
  static const Color readyIconBg = Color(0xFFD1FAE5);

  // 6. Active Trip Module (Dominant Operational Green)
  static const Color activeTripBg = Color(0xFF064E3B);
  static const Color activeTripCardBg = Color(0xFF065F46);
  static const Color activeTripBorder = Color(0xFF10B981);

  // 7. Today's Schedule Module (Deep Teal / Dark Slate Green)
  static const Color scheduleBg = Color(0xFFF0FDF4);
  static const Color scheduleHeaderBg = Color(0xFF0F766E);
  static const Color scheduleBorder = Color(0xFF0F766E);
  static const Color scheduleAccent = Color(0xFF0F766E);
  static const Color scheduleIconBg = Color(0xFFCCFBF1);

  // 8. Trip History Module (Ocean / Slate Blue)
  static const Color historyBg = Color(0xFFF0F9FF);
  static const Color historyHeaderBg = Color(0xFF0369A1);
  static const Color historyBorder = Color(0xFF0284C7);
  static const Color historyAccent = Color(0xFF0284C7);
  static const Color historyIconBg = Color(0xFFE0F2FE);

  // 9. Quick Actions Module (Clean Neutral Action Zone)
  static const Color quickActionsBg = Colors.white;
  static const Color quickActionsHeaderBg = Color(0xFF115E59);
  static const Color quickActionsBorder = Color(0xFFE2E8F0);
  static const Color quickActionsAccent = Color(0xFF0F766E);
  static const Color quickActionsIconBg = Color(0xFFF1F5F9);

  // Quick Action Differentiated Colors
  static const Color quickHistoryBg = Color(0xFFF0FDF4);
  static const Color quickHistoryBorder = Color(0xFFBBF7D0);
  static const Color quickHistoryIcon = Color(0xFF059669);

  static const Color quickIncidentBg = Color(0xFFFFFBEB);
  static const Color quickIncidentBorder = Color(0xFFFDE68A);
  static const Color quickIncidentIcon = Color(0xFFD97706);

  static const Color quickAdminBg = Color(0xFFF1F5F9);
  static const Color quickAdminBorder = Color(0xFFCBD5E1);
  static const Color quickAdminIcon = Color(0xFF475569);

  static const Color quickSosBg = Color(0xFFFEF2F2);
  static const Color quickSosBorder = Color(0xFFFECACA);
  static const Color quickSosIcon = Color(0xFFDC2626);

  // Feature Card Backgrounds (from City-Ride)
  static const Color routePlannerBg = Color(0xFFE8F8F0);
  static const Color routePlannerBorder = Color(0xFFCEF0DD);
  static const Color routePlannerIcon = Color(0xFF047857);

  static const Color complaintsBg = Color(0xFFFEEAEA);
  static const Color complaintsBorder = Color(0xFFFCC8C8);
  static const Color complaintsIcon = Color(0xFFEF4444);

  // Driver Cockpit HUD Specific Colors
  static const Color cockpitHudBg = Color(0xFF0B1320);
  static const Color cockpitCardBg = Color(0xFF162235);
  static const Color cockpitBorder = Color(0xFF263852);
  static const Color hudGlowGreen = Color(0xFF00FF9D);
  static const Color hudGlowAmber = Color(0xFFFFB020);
  static const Color hudGlowRed = Color(0xFFFF334B);

  // Typography Getters
  static TextStyle get appTitle => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: primaryGreen,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get sectionHeading => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: textDark,
        letterSpacing: 0.6,
        height: 1.3,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        color: textDark,
        letterSpacing: 0.0,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textDark,
        letterSpacing: 0.0,
        height: 1.5,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: textMuted,
        letterSpacing: 0.0,
        height: 1.5,
      );

  static TextStyle get smallMeta => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
        letterSpacing: 0.0,
        height: 1.4,
      );

  static TextStyle get uppercaseLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textMuted,
        letterSpacing: 0.5,
        height: 1.3,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
        height: 1.25,
      );

  // Theme Data Builder
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.35),
      headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.3),
      headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.25),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textDark, letterSpacing: -0.2),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textDark, letterSpacing: -0.15),
      titleSmall: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: textDark, letterSpacing: -0.1),
      bodyLarge: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w400, color: textDark),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textDark),
      bodySmall: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: textMuted),
      labelLarge: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w600, color: textDark),
      labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted, letterSpacing: 0.2),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: primaryGreen,
      textTheme: interTextTheme,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: cardBg,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: textDark,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceDark,
        contentTextStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        elevation: 6,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
      headlineLarge: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w400, color: const Color(0xFFE2E8F0)),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFCBD5E1)),
      bodySmall: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: cockpitHudBg,
      primaryColor: primaryGreen,
      textTheme: interTextTheme,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: cockpitCardBg,
        error: errorColor,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cockpitCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cockpitBorder, width: 1),
        ),
      ),
    );
  }
}
