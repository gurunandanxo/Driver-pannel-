import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact Today's Performance Card for the CityRide Driver Dashboard.
///
/// Implements Section 8:
/// - Header: "TODAY" section label.
/// - 3-column statistics: Trips (e.g. 3 / 8), On Time (e.g. 98%), Distance (e.g. 86 km).
/// - Subline: Shift (07:30 AM – 04:30 PM) • Driving Time (2h 45m).
class TodayPerformanceCard extends StatelessWidget {
  final String tripsText;
  final String onTimeText;
  final String distanceText;
  final String shiftTimeText;
  final String drivingTimeText;

  const TodayPerformanceCard({
    super.key,
    this.tripsText = "3 / 8",
    this.onTimeText = "98%",
    this.distanceText = "86 km",
    this.shiftTimeText = "07:30 AM – 04:30 PM",
    this.drivingTimeText = "2h 45m",
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

          // 3-column stats
          Row(
            children: [
              Expanded(
                child: _buildStatCell(
                  value: tripsText,
                  label: "Trips",
                  valueColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCell(
                  value: onTimeText,
                  label: "On Time",
                  valueColor: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCell(
                  value: distanceText,
                  label: "Distance",
                  valueColor: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Subline: Shift + Driving time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shift: $shiftTimeText",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                "Driving: $drivingTimeText",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
