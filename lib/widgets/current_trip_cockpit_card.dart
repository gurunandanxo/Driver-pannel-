import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Primary Current Trip Cockpit Card for the CityRide Driver Dashboard.
///
/// Implements Section 3 & 4 of the specification:
/// - Operational shift status: 🟢 ON DUTY / ⚪ OFF DUTY, route code & name, Trip 3 of 8.
/// - Next Stop panel: 📍 Next stop name, ETA badge (06 min), On-time badge (🟢 ON TIME +1 min).
/// - Route Progress bar: dynamic stops progress (e.g. 8 / 11 stops completed).
/// - Primary Action: [ VIEW ROUTE ] / [ OPEN CURRENT TRIP ].
class CurrentTripCockpitCard extends StatelessWidget {
  final bool isTripActive;
  final String statusLabel;
  final Color statusColor;
  final String routeCode;
  final String routeName;
  final String tripNumberText;
  final String nextStopName;
  final String etaText;
  final String punctualityText;
  final String punctualitySubText;
  final int completedStops;
  final int totalStops;
  final VoidCallback? onViewRoute;
  final VoidCallback? onOpenTrip;

  const CurrentTripCockpitCard({
    super.key,
    this.isTripActive = true,
    this.statusLabel = "ON DUTY",
    this.statusColor = const Color(0xFF10B981),
    this.routeCode = "CR101",
    this.routeName = "Central → Tumakuru",
    this.tripNumberText = "Trip 3 / 8",
    this.nextStopName = "Tumakuru Bus Stand",
    this.etaText = "06 min",
    this.punctualityText = "ON TIME",
    this.punctualitySubText = "+1 min",
    this.completedStops = 8,
    this.totalStops = 11,
    this.onViewRoute,
    this.onOpenTrip,
  });

  @override
  Widget build(BuildContext context) {
    final double progressFraction = totalStops > 0 ? (completedStops / totalStops).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Operational Status + Trip Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isTripActive ? statusColor : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isTripActive ? statusLabel : "OFF DUTY",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isTripActive ? statusColor : const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                tripNumberText,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Route code + route origin -> destination
          Text(
            "$routeCode • $routeName",
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 14),

          // Row 3: NEXT STOP panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "NEXT STOP",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // ETA + On-time badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF059669)),
                              const SizedBox(width: 4),
                              Text(
                                "ETA $etaText",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            "🟢 $punctualityText ($punctualitySubText)",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
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

          const SizedBox(height: 14),

          // Row 4: Route Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Route Progress",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                "$completedStops / $totalStops stops completed",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(CityRideTheme.primaryGreen),
            ),
          ),

          const SizedBox(height: 16),

          // Row 5: Action buttons: [ VIEW ROUTE ] & [ OPEN CURRENT TRIP ]
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onViewRoute,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "VIEW ROUTE",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF334155),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onOpenTrip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CityRideTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isTripActive ? "OPEN CURRENT TRIP" : "START TRIP",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
