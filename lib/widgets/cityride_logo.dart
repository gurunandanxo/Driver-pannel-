import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class CityRideDriverLogo extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool showDriverBadge;

  const CityRideDriverLogo({
    super.key,
    this.size = 32,
    this.isDark = false,
    this.showDriverBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Logo Icon with the official CityRide bus graphic
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: CityRideTheme.accentGreen.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    color: CityRideTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                      size: size * 0.60,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // CITYRIDE Brand Text
        Text(
          "CITYRIDE",
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : CityRideTheme.primaryGreen,
            fontSize: size * 0.72,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
          ),
        ),
        if (showDriverBadge) ...[
          const SizedBox(width: 6),
          // DRIVER Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "DRIVER",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0369A1),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
