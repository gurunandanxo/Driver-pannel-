import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/transit_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/geo_utils.dart';
import '../../models/trip_models.dart';
import '../../services/driver_settings_service.dart';
import '../../services/emergency_sos_service.dart';
import '../../services/gps_service.dart';
import '../../services/trip_engine.dart';
import '../../widgets/driver_status_badge.dart';
import '../../widgets/live_driver_map.dart';
import '../../widgets/route_timeline_widget.dart';
import '../../widgets/sos_hold_button.dart';
import '../dashboard/driver_dashboard_screen.dart';
import '../incidents/report_incident_modal.dart';
import '../sos/emergency_sos_screen.dart';
import '../summary/trip_summary_screen.dart';

class DriverCockpitScreen extends StatefulWidget {
  const DriverCockpitScreen({super.key});

  @override
  State<DriverCockpitScreen> createState() => _DriverCockpitScreenState();
}

class _DriverCockpitScreenState extends State<DriverCockpitScreen> {
  final _tripEngine = TripEngine();
  final _gpsService = GpsService();
  final _settingsService = DriverSettingsService();
  final _sosService = EmergencySosService();
  bool _hasNavigatedToSummary = false;

  @override
  void initState() {
    super.initState();
    _tripEngine.addListener(_onStateChanged);
    _gpsService.addListener(_onStateChanged);
    _settingsService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _tripEngine.removeListener(_onStateChanged);
    _gpsService.removeListener(_onStateChanged);
    _settingsService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;

    // If destination was reached and trip auto-completed, safely navigate to summary screen
    if (_tripEngine.workflowState == DriverWorkflowState.destinationReached &&
        _tripEngine.lastCompletedSummary != null &&
        !_hasNavigatedToSummary) {
      _hasNavigatedToSummary = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TripSummaryScreen(summary: _tripEngine.lastCompletedSummary!),
            ),
          );
        }
      });
      return;
    }

    setState(() {});
  }

  void _handleBackNavigation() {
    if (!_tripEngine.isTripActive) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
        );
      }
      return;
    }

    final isDark = _settingsService.isNightHudMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Trip in Progress",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : CityRideTheme.textDark,
          ),
        ),
        content: Text(
          "Do you want to leave the trip screen? The trip will continue running live in the background.",
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "STAY",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : CityRideTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CityRideTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "GO TO DASHBOARD",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEndTrip() {
    final isDark = _settingsService.isNightHudMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.stop_circle_outlined, color: CityRideTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            Text(
              "END TRIP?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : CityRideTheme.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to end this trip? Your current trip progress will be saved.",
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "CANCEL",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : CityRideTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _tripEngine.endTripEarly(reason: 'Driver manually ended trip');
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DriverDashboardScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CityRideTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "END TRIP",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStartTrip() {
    final success = _tripEngine.startTrip();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please ensure bus and inspection are completed before starting trip.",
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: CityRideTheme.warningColor,
        ),
      );
    }
  }

  void _handleSosTrigger() {
    final trip = _tripEngine.activeTrip;
    _sosService.triggerSos(
      tripId: trip?.id,
      vehicleId: trip?.bus.busNumber,
      routeId: trip?.route.id,
      routeName: trip?.route.routeName,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settingsService.isNightHudMode;
    final trip = _tripEngine.activeTrip;
    final isTripActive = _tripEngine.isTripActive;
    final currentStop = _tripEngine.currentStop;
    final nextStop = _tripEngine.nextStop;
    final isGpsLive = _gpsService.isGpsLive;
    final delayMinutes = _tripEngine.delayMinutes;
    final activeRoute = trip?.route ?? _tripEngine.verifiedRoute;
    final stopsList = activeRoute?.stops ?? TransitCatalog.cr103Stops;

    final themeData = isDark ? CityRideTheme.darkTheme : CityRideTheme.lightTheme;

    return Theme(
      data: themeData,
      child: Scaffold(
        backgroundColor: isDark ? CityRideTheme.cockpitHudBg : CityRideTheme.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Top Telemetry Bar: Bus, Route, Direction, Status, GPS Live, Delay & Back Navigation
              _buildTopActiveTripHeader(isDark, trip, activeRoute, isGpsLive, delayMinutes, isTripActive),

              // 2. Center Body (Next Stop Card, Live Map, Route Sequence)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Next Stop Card with Automatic Arrival ETA or Ready For Departure banner
                      _buildNextStopCard(isDark, currentStop, nextStop, activeRoute, isTripActive),
                      const SizedBox(height: 12),

                      // Live Interactive Transit Map (with graceful fallback)
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: LiveDriverMap(
                          stops: stopsList,
                          currentLat: _gpsService.latitude,
                          currentLon: _gpsService.longitude,
                          headingDegrees: _gpsService.headingDegrees,
                          currentStopIndex: _tripEngine.currentStopIndex,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Route Stops Vertical Timeline (Sequence Order Protection)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.alt_route_rounded,
                                      size: 18,
                                      color: isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "ROUTE STOP SEQUENCE",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isTripActive
                                      ? "Stop ${(_tripEngine.currentStopIndex + 1).clamp(1, stopsList.length)} of ${stopsList.length}"
                                      : "${stopsList.length} Total Stops",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : CityRideTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            RouteTimelineWidget(
                              stops: stopsList,
                              currentStopIndex: isTripActive ? _tripEngine.currentStopIndex : -1,
                              isDark: isDark,
                              tripStartTime: trip?.startedAt,
                              delayMinutes: delayMinutes,
                              etaToNextStopSeconds: _tripEngine.etaToNextStopSeconds,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 3. Responsive Bottom Action Dock
              _buildBottomActionDock(isDark, isTripActive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActiveTripHeader(
    bool isDark,
    DriverTrip? trip,
    TransitRoute? activeRoute,
    bool isGpsLive,
    int delayMinutes,
    bool isTripActive,
  ) {
    final leg = _tripEngine.legDirection;
    final isReturning = leg == TripLegDirection.returning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Back to Home navigation + Route & Bus Pill + Direction/Status Pill
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : CityRideTheme.textDark,
                      size: 22,
                    ),
                    tooltip: isTripActive
                        ? "Return to Dashboard (Trip continues in background)"
                        : "Return to Dashboard",
                    onPressed: _handleBackNavigation,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF047857) : CityRideTheme.lightGreenChip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activeRoute?.routeCode ?? "CR103",
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : CityRideTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: !isTripActive
                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                          : (isReturning
                              ? (isDark ? const Color(0xFF3B1E54) : const Color(0xFFF3E8FF))
                              : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE))),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      !isTripActive
                          ? "READY"
                          : (isReturning ? "RETURNING" : "OUTBOUND"),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: !isTripActive
                            ? (isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted)
                            : (isReturning
                                ? (isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE))
                                : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trip?.bus.busNumber ?? _tripEngine.verifiedBus?.busNumber ?? "KA06F8558",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : CityRideTheme.textDark,
                    ),
                  ),
                ],
              ),

              // Right: GPS Live Status & Night Mode Toggle
              Row(
                children: [
                  GpsStatusBadge(
                    isLive: isGpsLive,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Night Mode Button
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                      color: isDark ? Colors.white : CityRideTheme.textDark,
                    ),
                    onPressed: () => _settingsService.toggleNightHudMode(!isDark),
                    tooltip: "Toggle Night Mode HUD",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Secondary Telemetry Row: Delay & Live Coordinates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DelayStatusBadge(
                delayMinutes: delayMinutes,
                isDark: isDark,
              ),
              Text(
                "LAT: ${_gpsService.latitude.toStringAsFixed(4)}  LON: ${_gpsService.longitude.toStringAsFixed(4)}",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEXT BUS STOP / READY FOR DEPARTURE CARD ---
  Widget _buildNextStopCard(
    bool isDark,
    TransitStop? currentStop,
    TransitStop? nextStop,
    TransitRoute? activeRoute,
    bool isTripActive,
  ) {
    if (!isTripActive) {
      final firstStop = (activeRoute?.stops.isNotEmpty ?? false)
          ? activeRoute!.stops.first
          : TransitStop(
              id: 'ST_KSRTC',
              name: 'KSRTC Bus Stand',
              kannadaName: 'ಕೆ.ಎಸ್.ಆರ್.ಟಿ.ಸಿ ಬಸ್ ನಿಲ್ದಾಣ',
              latitude: 13.3395,
              longitude: 77.1005,
              sequenceOrder: 1,
              routeId: 'ROUTE_CR103',
            );

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF047857).withOpacity(0.3) : CityRideTheme.lightGreenChip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.departure_board_rounded, size: 13, color: CityRideTheme.primaryGreen),
                      const SizedBox(width: 5),
                      Text(
                        "READY FOR DEPARTURE",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Origin: ${firstStop.name}",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              firstStop.name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : CityRideTheme.textDark,
                letterSpacing: -0.2,
              ),
            ),
            if (firstStop.kannadaName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                firstStop.kannadaName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _handleStartTrip,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(
                  "START TRIP",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final etaSeconds = _tripEngine.etaToNextStopSeconds;
    final distanceMeters = _tripEngine.distanceToNextStopMeters;
    final isReturning = _tripEngine.legDirection == TripLegDirection.returning;
    final target = nextStop ?? currentStop;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isReturning
                      ? (isDark ? const Color(0xFF3B1E54) : const Color(0xFFF3E8FF))
                      : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isReturning ? "RETURNING TO KSRTC BUS STAND" : "NEXT STOP",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isReturning
                        ? (isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE))
                        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    GeoUtils.formatEta(etaSeconds),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "•  ${GeoUtils.formatDistance(distanceMeters)}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // English Target Stop Name
          Text(
            target?.name ?? "Final Stop",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : CityRideTheme.textDark,
              letterSpacing: -0.2,
            ),
          ),
          // Kannada Stop Name
          if (target != null && target.kannadaName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              target.kannadaName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Current Stop / Manual Advance Option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Current: ${currentStop?.name ?? 'En Route'}",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                ),
              ),
              TextButton.icon(
                onPressed: () => _tripEngine.manualAdvanceToNextStop(),
                icon: const Icon(Icons.check_circle_outline, size: 14),
                label: Text(
                  "Arrived at Stop",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: CityRideTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BOTTOM ACTION DOCK ---
  Widget _buildBottomActionDock(bool isDark, bool isTripActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
          ),
        ),
      ),
      child: isTripActive
          ? Row(
              children: [
                // 1. END / STOP TRIP Button
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _handleEndTrip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        side: const BorderSide(color: CityRideTheme.errorColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_circle_rounded, size: 16, color: CityRideTheme.errorColor),
                          const SizedBox(height: 2),
                          Text(
                            "END TRIP",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: CityRideTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Report Incident Button
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ReportIncidentModal(),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        side: BorderSide(
                          color: isDark ? CityRideTheme.cockpitBorder : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 16, color: CityRideTheme.warningColor),
                          const SizedBox(height: 2),
                          Text(
                            "INCIDENT",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : CityRideTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Emergency SOS Hold-to-Activate Button
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 50,
                    child: SosHoldButton(
                      onSosTriggered: _handleSosTrigger,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _handleBackNavigation,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(
                        "DASHBOARD",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? CityRideTheme.cockpitBorder : const Color(0xFFCBD5E1),
                        ),
                        foregroundColor: isDark ? Colors.white : CityRideTheme.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _handleStartTrip,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        "START TRIP",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CityRideTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
