import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/incident_service.dart';
import 'report_incident_modal.dart';

class ActiveIncidentsScreen extends StatefulWidget {
  const ActiveIncidentsScreen({super.key});

  @override
  State<ActiveIncidentsScreen> createState() => _ActiveIncidentsScreenState();
}

class _ActiveIncidentsScreenState extends State<ActiveIncidentsScreen> {
  final _incidentService = IncidentService();

  @override
  void initState() {
    super.initState();
    _incidentService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _incidentService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final incidents = _incidentService.incidents;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Incidents & Route Alerts",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ReportIncidentModal(),
          );
        },
        backgroundColor: CityRideTheme.warningColor,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: Text(
          "REPORT INCIDENT",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: incidents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 48, color: CityRideTheme.accentGreen),
                  const SizedBox(height: 12),
                  Text(
                    "No Active Incidents",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CityRideTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "All transit corridors operating normally",
                    style: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final inc = incidents[index];
                final timeStr = DateFormat('hh:mm a').format(inc.reportedAt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: CityRideTheme.errorColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                inc.incidentType,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: CityRideTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: inc.status == 'RESOLVED'
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              inc.status,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: inc.status == 'RESOLVED'
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        inc.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CityRideTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_rounded, size: 14, color: CityRideTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            inc.incidentCode,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: CityRideTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.access_time_rounded, size: 14, color: CityRideTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: CityRideTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
