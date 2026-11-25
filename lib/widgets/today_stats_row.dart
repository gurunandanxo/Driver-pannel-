import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact Today's Stats Card component for the CityRide Driver Dashboard.
///
/// Implements:
/// - Section label "TODAY" (small, bold, uppercase, gray).
/// - 2-column equal-width grid with generous 28px gap.
/// - Column 1: "2h 45m" bold large / "Driving" small gray below.
/// - Column 2: "3/8" bold large / "Trips" small gray below.
/// - Bounded constraints with text-overflow ellipsis protection.
class TodayStatsRow extends StatelessWidget {
  final String drivingTime;
  final String tripsCount;

  const TodayStatsRow({
    super.key,
    this.drivingTime = "2h 45m",
    this.tripsCount = "3/8",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section label: "TODAY"
          Text(
            "TODAY",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // 2-column grid, equal width with generous 28px gap
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatCell(
                    value: drivingTime,
                    label: "Driving",
                    valueColor: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: _buildStatCell(
                    value: tripsCount,
                    label: "Trips",
                    valueColor: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
