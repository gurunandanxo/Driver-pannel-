import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/driver_models.dart';
import '../models/trip_models.dart';
import '../models/vehicle_model.dart';

/// Clean, modern, responsive Shift Summary card component for CityRide Driver Dashboard.
///
/// Implements:
/// - Consistent 16px internal padding and 16px rounded corners.
/// - Header row with clock icon, title with ellipsis, and safe right-margined ACTIVE SHIFT status pill.
/// - Driver identification & depot info row with safe spacing.
/// - Route row with responsive LayoutBuilder: horizontal text only, min-width SET BUS chip,
///   and vertical stacking if horizontal space is narrow (< 290px).
/// - 3-column equal-width grid (repeat(3, 1fr)) with 12px gap, equal heights, vertical alignment,
///   and single-line ellipsis truncation on values.
class ShiftSummaryCard extends StatelessWidget {
  final DriverProfile? driver;
  final bool isBusVerified;
  final BusVehicle? verifiedBus;
  final TransitRoute? verifiedRoute;
  final VoidCallback? onSetBus;
  final VoidCallback? onResetBus;
  final String shiftStartTime;
  final String completedTripsText;
  final String punctualityText;

  const ShiftSummaryCard({
    super.key,
    this.driver,
    this.isBusVerified = false,
    this.verifiedBus,
    this.verifiedRoute,
    this.onSetBus,
    this.onResetBus,
    this.shiftStartTime = "07:30 AM",
    this.completedTripsText = "2 Trips (16.8 km)",
    this.punctualityText = "100% On Time",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CityRideTheme.shiftCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CityRideTheme.shiftCardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0284C7),
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
          // 1. Top Header Row: Clock Icon + "TODAY'S SHIFT SUMMARY" + "ACTIVE SHIFT" Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: CityRideTheme.shiftAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "TODAY'S SHIFT SUMMARY",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CityRideTheme.shiftBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CityRideTheme.shiftCardBorder),
                ),
                child: Text(
                  "ACTIVE SHIFT",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: CityRideTheme.shiftBadgeText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Info Row: Driver Identification & Depot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Driver: ${driver?.name ?? 'Ramesh Gowda'} • ${driver?.driverId ?? 'TUM-DRV-1042'}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Depot #1",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Route Row: Assigned Route with responsive horizontal "SET BUS" Action / Verified Badge
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isTight = constraints.maxWidth < 290;

              final routeTextWidget = Text(
                "Assigned Route: ${verifiedRoute?.routeCode ?? 'CR101'} ${verifiedRoute?.routeName ?? 'Central Corridor'}",
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

              final actionWidget = isBusVerified
                  ? InkWell(
                      onTap: onResetBus,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${verifiedBus?.busNumber ?? 'KA06F8558'} • VERIFIED",
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onSetBus,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 84),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                          decoration: BoxDecoration(
                            color: CityRideTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: CityRideTheme.primaryGreen.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_bus_outlined, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                "SET BUS",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

              if (isTight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    routeTextWidget,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: actionWidget,
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: routeTextWidget),
                    const SizedBox(width: 8),
                    actionWidget,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 14),

          // 4. Equal-Height 3-Column Stat Grid (repeat(3, 1fr) with 12px gap)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildStatCell(
                    icon: Icons.schedule_rounded,
                    label: "SHIFT START",
                    value: shiftStartTime,
                    iconColor: const Color(0xFF64748B),
                    valueColor: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCell(
                    icon: Icons.directions_bus_rounded,
                    label: "COMPLETED",
                    value: completedTripsText,
                    iconColor: CityRideTheme.shiftAccent,
                    valueColor: CityRideTheme.shiftAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCell(
                    icon: Icons.timer_outlined,
                    label: "PUNCTUALITY",
                    value: punctualityText,
                    iconColor: const Color(0xFF059669),
                    valueColor: const Color(0xFF059669),
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
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0F2FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
