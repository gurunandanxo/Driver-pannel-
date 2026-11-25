import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Primary Hero Card for the Trip-Focused CityRide Driver Dashboard.
///
/// Supports two conditional modes:
/// 1. Active Trip State (isTripActive == true):
///    - Status row: green dot + "ON DUTY" (bold green uppercase, 12-13px).
///    - Route + vehicle row: "CR101 • CENTRAL → TUMAKURU" bold 16-18px + "Bus: KA06F8558" with bus icon.
///    - Next Stop panel: Inset tinted rounded rectangle with "NEXT STOP", stop name, and "ETA 06 min" badge.
///    - Full-width divider with 12-16px vertical margins.
///    - Punctuality + time row: green dot + "ON TIME", "08:42 AM" bold time, "Trip 3 of 8".
///    - Primary CTA button: Full-width "OPEN CURRENT TRIP" in solid dark green with rounded corners.
///
/// 2. Off-Duty / Idle State (isTripActive == false):
///    - Status row: gray dot + "OFF DUTY" (bold gray uppercase, 12-13px).
///    - Message: "No trip in progress. Start your shift to begin." (centered, regular weight).
///    - CTA button: Full-width "START SHIFT" (solid dark green, 48px height).
class ActiveTripHeroCard extends StatelessWidget {
  final bool isTripActive;
  final String statusText;
  final Color statusColor;
  final String? routeLine;
  final String routeCode;
  final String originName;
  final String destinationName;
  final String busNumber;
  final String nextStopLabel;
  final String nextStopName;
  final String etaText;
  final String punctualityText;
  final String timeText;
  final String tripProgressText;
  final String ctaText;
  final String? headerTitle;
  final String? badgeText;
  final VoidCallback? onOpenCurrentTrip;

  const ActiveTripHeroCard({
    super.key,
    this.isTripActive = true,
    this.statusText = "ON DUTY",
    this.statusColor = const Color(0xFF10B981),
    this.routeLine,
    this.routeCode = "CR101",
    this.originName = "CENTRAL",
    this.destinationName = "TUMAKURU",
    this.busNumber = "KA06F8558",
    this.nextStopLabel = "NEXT STOP",
    this.nextStopName = "Tumakuru Bus Stand",
    this.etaText = "ETA 06 min",
    this.punctualityText = "ON TIME",
    this.timeText = "08:42 AM",
    this.tripProgressText = "Trip 3 of 8",
    this.ctaText = "OPEN CURRENT TRIP",
    this.headerTitle,
    this.badgeText,
    this.onOpenCurrentTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: isTripActive ? _buildActiveTripContent() : _buildIdleOffDutyContent(),
    );
  }

  Widget _buildActiveTripContent() {
    final String formattedRoute = routeLine ?? "$routeCode • $originName → $destinationName";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // a) Status row: Green filled dot + "ON DUTY" in bold uppercase + optional headerTitle + optional badgeText
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                if (headerTitle != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    headerTitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                ),
                child: Text(
                  badgeText!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF065F46),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // b) Route + vehicle row
        Text(
          formattedRoute,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.directions_bus_outlined,
              size: 15,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              "Bus: $busNumber",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // c) Next Stop panel (visually distinct sub-block, mini live-tracking widget)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            nextStopLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          etaText,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                nextStopName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // d) Divider — thin horizontal rule with vertical margin 12-16px
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
        ),

        // e) Punctuality + time row (structured for vertical balance & 0 overflow)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      punctualityText,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF059669),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  timeText,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Text(
                tripProgressText,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // f) Primary CTA button — full width, solid dark green, ~48px height, rounded corners
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onOpenCurrentTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: CityRideTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              ctaText,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleOffDutyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status row: Gray filled dot + "OFF DUTY" in bold uppercase
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "OFF DUTY",
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Empty state message: centered, gray, regular weight
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "No trip in progress. Start your shift to begin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // CTA button: "START SHIFT" (solid dark green, 48px height, rounded corners)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onOpenCurrentTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: CityRideTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              "START SHIFT",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
