import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trip_models.dart';
import '../../services/trip_engine.dart';
import '../dashboard/driver_dashboard_screen.dart';
import '../history/driver_history_screen.dart';

class TripSummaryScreen extends StatelessWidget {
  final TripSummary summary;

  const TripSummaryScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final startTimeStr = DateFormat('hh:mm a').format(summary.startTime);
    final endTimeStr = DateFormat('hh:mm a').format(summary.endTime);
    final durationMins = summary.duration.inMinutes > 0 ? summary.duration.inMinutes : 1;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success Badge Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: CityRideTheme.lightGreenChip,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: CityRideTheme.primaryGreen.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: CityRideTheme.primaryGreen,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "TRIP COMPLETED",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: CityRideTheme.primaryGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Round-Trip Journey Finished Successfully",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CityRideTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Route & Vehicle Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: CityRideTheme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route & Bus Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: CityRideTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        summary.routeCode,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Round-Trip",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: CityRideTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary.routeSummary,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: CityRideTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: CityRideTheme.lightGreenChip,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Vehicle",
                                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: CityRideTheme.textMuted),
                                  ),
                                  Text(
                                    summary.busNumber,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: CityRideTheme.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: CityRideTheme.dividerColor),
                        const SizedBox(height: 14),

                        // Metric Rows
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem("Started", startTimeStr),
                            _buildSummaryItem("Completed", endTimeStr),
                            _buildSummaryItem("Duration", "$durationMins min"),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: CityRideTheme.dividerColor),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem("Stops Visited", "${summary.stopsCompleted} of ${summary.totalStops}"),
                            _buildSummaryItem(
                              "Schedule Delay",
                              summary.delayMinutes > 0 ? "+${summary.delayMinutes} min" : "On Time",
                            ),
                            _buildSummaryItem(
                              "Incidents",
                              "${summary.incidentsCount}",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Round-Trip Route Sequence Visualization Card
                  if (summary.stops.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CityRideTheme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.route_rounded, size: 16, color: CityRideTheme.primaryGreen),
                              const SizedBox(width: 6),
                              Text(
                                "JOURNEY STOPS COMPLETED",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: CityRideTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: summary.stops.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final stop = entry.value;
                              final isLast = idx == summary.stops.length - 1;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: CityRideTheme.primaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                      if (!isLast)
                                        Container(
                                          width: 2,
                                          height: 22,
                                          color: const Color(0xFF86EFAC),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 1, bottom: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stop.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: CityRideTheme.textDark,
                                            ),
                                          ),
                                          if (stop.kannadaName.isNotEmpty)
                                            Text(
                                              stop.kannadaName,
                                              style: GoogleFonts.notoSansKannada(
                                                fontSize: 11,
                                                color: CityRideTheme.textMuted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),

                  // Action Buttons: Primary BACK TO DASHBOARD & Secondary VIEW TRIP HISTORY
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        TripEngine().finishTripAndReturnToDashboard();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.dashboard_rounded, size: 20, color: Colors.white),
                      label: Text(
                        "BACK TO DASHBOARD",
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CityRideTheme.primaryGreen,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DriverHistoryScreen()),
                        );
                      },
                      icon: const Icon(Icons.history_rounded, size: 18, color: CityRideTheme.primaryGreen),
                      label: Text(
                        "VIEW TRIP HISTORY",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CityRideTheme.primaryGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: CityRideTheme.primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CityRideTheme.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: CityRideTheme.textDark,
          ),
        ),
      ],
    );
  }
}
