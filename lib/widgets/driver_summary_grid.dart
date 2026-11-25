import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/driver_models.dart';

/// Compact Driver Summary Grid Card for the CityRide Driver Dashboard.
///
/// Positioned directly above the Quick Actions module.
/// Features:
/// - Driver Identity Row: Profile avatar, driver full name, badge/license ID, and TODAY tag.
/// - 4-metric horizontal stat grid:
///   1. Trips completed today ('3/8 Trips')
///   2. Driving hours ('2h 45m Driving')
///   3. On-time performance ('98% On-time')
///   4. Driver rating ('4.9 ★ Rating')
/// - Responsive, rounded card (16px) with zero overflow on 360px mobile viewports.
class DriverSummaryGrid extends StatelessWidget {
  final DriverProfile? driver;
  final String tripsCompleted;
  final String hoursDriven;
  final String onTimeRate;
  final String rating;

  const DriverSummaryGrid({
    super.key,
    this.driver,
    this.tripsCompleted = '3/8',
    this.hoursDriven = '2h 45m',
    this.onTimeRate = '98%',
    this.rating = '4.9 ★',
  });

  @override
  Widget build(BuildContext context) {
    final name = driver?.name ?? 'Ramesh Gowda';
    final badgeId = driver?.driverId ?? 'TUM-DRV-1042';
    final initials = driver?.initials ?? 'RG';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
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
          // Top row: Driver Profile Identity
          Row(
            children: [
              // Avatar circle with initials
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: CityRideTheme.primaryGreen.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name & Badge Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ID: $badgeId',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Depot #1',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Section Pill: "TODAY"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TODAY',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
            ),
          ),

          // Horizontal Stat Grid with 4 Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCell(
                  icon: Icons.alt_route_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFECFDF5),
                  value: tripsCompleted,
                  label: 'Trips',
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricCell(
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  value: hoursDriven,
                  label: 'Driving',
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricCell(
                  icon: Icons.verified_outlined,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFFBEB),
                  value: onTimeRate,
                  label: 'On-time',
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildMetricCell(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFEAB308),
                  iconBg: const Color(0xFFFEFCE8),
                  value: rating,
                  label: 'Rating',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
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
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
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
