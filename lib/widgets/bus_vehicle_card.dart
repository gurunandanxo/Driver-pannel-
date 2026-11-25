import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Enlarged Primary Hero Vehicle Identity Card for the CityRide Driver Dashboard.
///
/// Implements:
/// - Prominent hero container with generous 20–22px padding and subtle elevation.
/// - Top row: Bus icon in a rounded icon badge + "ASSIGNED BUS" label + top-right status/action:
///   - If verified: green "VERIFIED ✓" pill (matching "YOUR ROUTE" badge style)
///   - If not verified: prominent outlined "VERIFY" button in primary green
/// - Hero registration plate: 24–26px bold dark text (the visual anchor of the card).
/// - Sub-line: Depot and route assignment (e.g. "Depot #1 • Route CR101") in 13–14px regular gray.
/// - Bounded constraints with full text-overflow ellipsis protection.
class BusVehicleCard extends StatelessWidget {
  final String label;
  final String busNumber;
  final String assignmentInfo;
  final bool isVerified;
  final VoidCallback? onTap;
  final VoidCallback? onVerify;

  const BusVehicleCard({
    super.key,
    this.label = "ASSIGNED BUS",
    this.busNumber = "KA06F8558",
    this.assignmentInfo = "Depot #1 • Route CR101",
    this.isVerified = true,
    this.onTap,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF7), // Soft mint / sage background tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? const Color(0xFFBBF7D0) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? onVerify,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left-edge solid brand accent bar
                  Container(
                    width: 4.5,
                    color: isVerified ? CityRideTheme.primaryGreen : const Color(0xFF94A3B8),
                  ),

                  // Card Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top row: Badge icon + label + Status/Action on the right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFBBF7D0),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus_rounded,
                                        size: 16,
                                        color: CityRideTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF475569),
                                          letterSpacing: 0.6,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Top-right status indicator or verify action
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: Color(0xFF15803D),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "VERIFIED",
                                        style: GoogleFonts.inter(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF15803D),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 32,
                                  child: OutlinedButton(
                                    onPressed: onVerify ?? onTap,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: CityRideTheme.primaryGreen,
                                      side: const BorderSide(
                                        color: CityRideTheme.primaryGreen,
                                        width: 1.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "VERIFY",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Hero focal element: Large bold registration plate number (35px)
                          Text(
                            busNumber,
                            style: GoogleFonts.inter(
                              fontSize: 35,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Sub-line: Depot and Route assignment details
                          Text(
                            assignmentInfo,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
