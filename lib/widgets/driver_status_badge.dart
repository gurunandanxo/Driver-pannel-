import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class GpsStatusBadge extends StatelessWidget {
  final bool isLive;
  final bool isDark;

  const GpsStatusBadge({
    super.key,
    this.isLive = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132E27) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLive ? CityRideTheme.accentGreen.withOpacity(0.5) : Colors.grey,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isLive ? CityRideTheme.accentGreen : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isLive ? "● GPS LIVE" : "GPS STALE",
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isLive
                  ? (isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen)
                  : Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class DelayStatusBadge extends StatelessWidget {
  final int delayMinutes;
  final bool isDark;

  const DelayStatusBadge({
    super.key,
    required this.delayMinutes,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    if (delayMinutes == 0) {
      bg = isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
      fg = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      text = 'ON TIME';
      icon = Icons.check_circle_outline_rounded;
    } else if (delayMinutes > 0) {
      bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
      fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      text = '+$delayMinutes MIN DELAY';
      icon = Icons.schedule_rounded;
    } else {
      bg = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF);
      fg = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      text = '${delayMinutes.abs()} MIN EARLY';
      icon = Icons.fast_forward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
