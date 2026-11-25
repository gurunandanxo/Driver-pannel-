import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/transit_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trip_models.dart';
import '../../models/vehicle_model.dart';
import '../../services/driver_auth_service.dart';
import '../../services/driver_settings_service.dart';
import '../../services/emergency_sos_service.dart';
import '../../services/gps_service.dart';
import '../../services/trip_engine.dart';
import '../../services/trip_history_service.dart';
import '../../widgets/driver_header.dart';
import '../../widgets/driver_status_badge.dart';
import '../../widgets/live_driver_map.dart';
import '../../widgets/active_trip_hero_card.dart';
import '../../widgets/bus_vehicle_card.dart';
import '../../widgets/safety_check_module.dart';
import '../../widgets/trip_action_card.dart';
import '../../widgets/driver_summary_grid.dart';
import '../../widgets/route_timeline_widget.dart';
import '../../widgets/sos_hold_button.dart';
import '../admin/contact_admin_screen.dart';
import '../duty/pre_trip_inspection_screen.dart';
import '../incidents/report_incident_modal.dart';
import '../profile/driver_profile_screen.dart';
import '../sos/emergency_sos_screen.dart';
import '../summary/trip_summary_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final TripEngine _tripEngine = TripEngine();
  final DriverAuthService _authService = DriverAuthService();
  final GpsService _gpsService = GpsService();
  final TripHistoryService _historyService = TripHistoryService();
  final DriverSettingsService _settingsService = DriverSettingsService();
  final EmergencySosService _sosService = EmergencySosService();

  int _currentTabIndex = 0; // 0 = Dashboard, 1 = Route, 2 = Trip, 3 = History
  HistoryFilter _historyFilter = HistoryFilter.today;

  final TextEditingController _busController = TextEditingController(
    text: 'KA06F8558',
  );
  final TextEditingController _routeController = TextEditingController(
    text: 'CR101',
  );
  bool _hasNavigatedToSummary = false;
  DateTime? _lastBackPressTime;

  void _handleDeviceBack() {
    // 1. If on an inner tab (Route, Trip, History), pop back to Dashboard
    if (_currentTabIndex != 0) {
      setState(() {
        _currentTabIndex = 0;
      });
      return;
    }

    // 2. If already on Dashboard (root), double-tap confirmation to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Press back again to exit CityRide Driver",
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    // Exits the app via native Android back dispatcher
    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _tripEngine.addListener(_onStateChanged);
    _authService.addListener(_onStateChanged);
    _gpsService.addListener(_onStateChanged);
    _historyService.addListener(_onStateChanged);
    _settingsService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _tripEngine.removeListener(_onStateChanged);
    _authService.removeListener(_onStateChanged);
    _gpsService.removeListener(_onStateChanged);
    _historyService.removeListener(_onStateChanged);
    _settingsService.removeListener(_onStateChanged);
    _busController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;

    // Check if background or live trip completed
    if (_tripEngine.workflowState == DriverWorkflowState.destinationReached &&
        _tripEngine.lastCompletedSummary != null &&
        !_hasNavigatedToSummary) {
      _hasNavigatedToSummary = true;
      // Auto-end: navigate back to Route page (Page 2) and show summary modal/screen
      setState(() {
        _currentTabIndex = 1;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tripEngine.lastCompletedSummary != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripSummaryScreen(summary: _tripEngine.lastCompletedSummary!),
            ),
          ).then((_) {
            _hasNavigatedToSummary = false;
            if (mounted) setState(() {});
          });
        }
      });
      return;
    }

    if (_tripEngine.workflowState != DriverWorkflowState.destinationReached) {
      _hasNavigatedToSummary = false;
    }

    setState(() {});
  }

  Future<void> _handleRefresh() async {
    await _tripEngine.refreshDashboard();
    await _historyService.fetchHistoryFromCloud();
    if (mounted) setState(() {});
  }

  Future<void> _verifyBus() async {
    final text = _busController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please type the bus registration number (e.g. KA06F8558).',
          ),
          backgroundColor: CityRideTheme.warningColor,
        ),
      );
      return;
    }
    await _tripEngine.validateBusNumber(text);
  }

  Future<void> _requestRouteChange(VoidCallback onProceed) async {
    if (_tripEngine.isTripActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Change Route?",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: CityRideTheme.textDark,
            ),
          ),
          content: Text(
            "This will stop the current trip and reset its route progress.",
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: CityRideTheme.textMuted,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                "CANCEL",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: CityRideTheme.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: CityRideTheme.errorColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "CHANGE ROUTE",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        _tripEngine.cancelActiveTripAndResetRoute();
        onProceed();
      }
    } else {
      onProceed();
    }
  }

  Future<void> _verifyRoute() async {
    final text = _routeController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a route code.'),
          backgroundColor: CityRideTheme.warningColor,
        ),
      );
      return;
    }
    await _tripEngine.validateRouteCode(text);
  }

  void _handleStartTrip() {
    final success = _tripEngine.startTrip();
    if (success) {
      setState(() {
        _currentTabIndex = 2; // Automatically switch to Page 3 (Trip)
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to start trip. Please ensure bus & route are verified and inspection completed.',
          ),
          backgroundColor: CityRideTheme.errorColor,
        ),
      );
    }
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
              setState(() {
                _currentTabIndex = 1; // Return to Route page
              });
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleDeviceBack();
      },
      child: Scaffold(
        backgroundColor: isDark && _currentTabIndex == 2
            ? CityRideTheme.cockpitHudBg
            : CityRideTheme.scaffoldBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Header: CITYRIDE | DRIVER | ALERT | PROFILE (Shortcut to Tab 4 Profile)
              DriverHeader(
                onProfileTap: () => setState(() => _currentTabIndex = 4),
              ),

              // Page Content Body
              Expanded(
                child: _buildCurrentPageBody(isDark),
              ),
            ],
          ),
        ),
        // Permanent 5-tab bottom navigation bar across all screens (including Live Trip)
        bottomNavigationBar: _buildPersistentBottomNavBar(),
      ),
    );
  }

  Widget _buildCurrentPageBody(bool isDark) {
    switch (_currentTabIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return _buildRoutePage();
      case 2:
        return _buildTripPage(isDark);
      case 3:
        return _buildHistoryPage();
      case 4:
        return const DriverProfileScreen(isEmbeddedTab: true);
      default:
        return _buildDashboardPage();
    }
  }

  // ===========================================================================
  // PERSISTENT BOTTOM NAVIGATION BAR (5 TABS: Dashboard, Route, Trip, History, Profile)
  // ===========================================================================
  Widget _buildPersistentBottomNavBar() {
    final isTripActive = _tripEngine.isTripActive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: CityRideTheme.dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: "Dashboard",
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.alt_route_rounded,
                label: "Route",
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.play_circle_outline_rounded,
                label: "Trip",
                isEnabled: isTripActive,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.history_rounded,
                label: "History",
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_rounded,
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isEnabled = true,
  }) {
    final isSelected = _currentTabIndex == index;
    final Color activeColor = CityRideTheme.primaryGreen;
    final Color inactiveColor = isEnabled ? CityRideTheme.textMuted : const Color(0xFFCBD5E1);

    return InkWell(
      onTap: () {
        if (!isEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "No live trip in progress. Select and start a route from the Route tab.",
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              backgroundColor: CityRideTheme.warningColor,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        setState(() => _currentTabIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                if (index == 2 && _tripEngine.isTripActive)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CityRideTheme.accentGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 1 — DASHBOARD (Trip-Focused: Active Trip Hero, Today's Stats, Safety Check, Quick Actions)
  // ===========================================================================
  Widget _buildDashboardPage() {
    final isBusVerified = _tripEngine.isBusVerified;
    final verifiedBus = _tripEngine.verifiedBus;
    final verifiedRoute = _tripEngine.verifiedRoute;
    final String busPlate = verifiedBus?.busNumber ?? 'KA06F8558';
    final int completedCount = _tripEngine.completedTripsToday.length;
    final driver = _authService.activeDriver;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: CityRideTheme.primaryGreen,
      displacement: 80,
      edgeOffset: 8,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ENLARGED HERO BUS / VEHICLE IDENTITY CARD (New 1st Primary Module)
            BusVehicleCard(
              label: "ASSIGNED BUS",
              busNumber: busPlate,
              assignmentInfo: "Depot #1 • Route ${verifiedRoute?.routeCode ?? 'CR101'}",
              isVerified: isBusVerified,
              onVerify: () => _showVehicleVerificationDialog(),
              onTap: () => _showVehicleVerificationDialog(),
            ),
            const SizedBox(height: 16),

            // 2. SAFETY CHECK CARD (2nd Position directly below vehicle hero card)
            SafetyCheckModule(
              inspection: _tripEngine.inspection,
              onToggleItem: (key, passed) {
                _tripEngine.toggleInspectionItem(key, passed);
                setState(() {});
              },
              onOpenInspectionScreen: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PreTripInspectionScreen()),
                );
              },
            ),
            const SizedBox(height: 14),

            // 3. TRIP NAVIGATION ACTION CARD (Directly below Safety Check)
            TripActionCard(
              title: "VIEW ROUTE & TRIPS",
              subtitle: "Assigned stops, route map & daily schedule",
              onTap: () => setState(() => _currentTabIndex = 1),
            ),
            const SizedBox(height: 16),

            // 4. NEW DRIVER SUMMARY GRID (Above Quick Actions, as the last section before it)
            DriverSummaryGrid(
              driver: driver,
              tripsCompleted: '${completedCount > 0 ? completedCount : 3}/8',
              hoursDriven: '2h 45m',
              onTimeRate: '98%',
              rating: '4.9 ★',
            ),
            const SizedBox(height: 16),

            // 5. QUICK ACTIONS MODULE (INCIDENT, DISPATCH, SOS)
            _buildPrioritizedQuickActionsModule(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 2 — ROUTE (Module 1: Route Entry & Verification -> Module 2: Current Trip -> Module 3: Today's Upcoming Schedule)
  // ===========================================================================
  Widget _buildRoutePage() {
    final isInspectionPassed = _tripEngine.isInspectionPassed;
    final isRouteVerified = _tripEngine.isRouteVerified;
    final isBusVerified = _tripEngine.isBusVerified;
    final verifiedRoute = _tripEngine.verifiedRoute;
    final verifiedBus = _tripEngine.verifiedBus;
    final isTripActive = _tripEngine.isTripActive;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: CityRideTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Generous bottom scroll-inset (96px) ensuring full visibility above docked navigation bar
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MODULE 1 — YOUR ROUTE (Route Entry & Corridor Verification — Always Fixed & First)
            _buildRouteModule(isRouteVerified, verifiedRoute),
            const SizedBox(height: 14),

            // 2. MODULE 2 — ACTIVE / CURRENT TRIP MODULE (Pulled up into prominent 2nd position)
            _buildActiveOrCurrentTripModule(
              isTripActive: isTripActive,
              isRouteVerified: isRouteVerified,
              isBusVerified: isBusVerified,
              isInspectionPassed: isInspectionPassed,
              verifiedBus: verifiedBus,
              verifiedRoute: verifiedRoute,
            ),
            const SizedBox(height: 14),

            // 3. MODULE 3 — TODAY'S UPCOMING SCHEDULE (Moves to 3rd position, showing only upcoming trips)
            if (isRouteVerified) ...[
              _buildUpcomingScheduleModule(),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGE 3 — TRIP (Live Trip Tracking & Cockpit)
  // ===========================================================================
  Widget _buildTripPage(bool isDark) {
    final trip = _tripEngine.activeTrip;
    final isTripActive = _tripEngine.isTripActive;
    final currentStop = _tripEngine.currentStop;
    final nextStop = _tripEngine.nextStop;
    final isGpsLive = _gpsService.isGpsLive;
    final delayMinutes = _tripEngine.delayMinutes;
    final activeRoute = trip?.route ?? _tripEngine.verifiedRoute;
    final stopsList = activeRoute?.stops ?? TransitCatalog.cr101Stops;

    if (!isTripActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  size: 44,
                  color: CityRideTheme.routeAccent,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "No Trip In Progress",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CityRideTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "To start tracking, please verify your route and click 'START THIS TRIP' on the Route tab.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: CityRideTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentTabIndex = 1),
                icon: const Icon(Icons.alt_route_rounded, size: 18),
                label: const Text("GO TO ROUTE SELECTION"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Active Trip Telemetry Header
          _buildTripTelemetryHeader(isDark, trip, activeRoute, isGpsLive, delayMinutes),
          const SizedBox(height: 12),

          // 2. Next Stop Card
          _buildNextStopCard(isDark, currentStop, nextStop, activeRoute, isTripActive),
          const SizedBox(height: 12),

          // 3. Live Interactive Map
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

          // 4. Route Stop Sequence Table (Full Round Trip: 11 stops for CR101 / 5 stops for CR102/CR103)
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
                      "Stop ${(_tripEngine.currentStopIndex + 1).clamp(1, stopsList.length)} of ${stopsList.length}",
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
                  currentStopIndex: _tripEngine.currentStopIndex,
                  isDark: isDark,
                  tripStartTime: trip?.startedAt,
                  delayMinutes: delayMinutes,
                  etaToNextStopSeconds: _tripEngine.etaToNextStopSeconds,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Live Trip Action Dock (END TRIP | INCIDENT | SOS)
          _buildTripBottomActionDock(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAGE 4 — TRIP HISTORY (Completed Trip Log with Full Round-Trip Summaries)
  // ===========================================================================
  Widget _buildHistoryPage() {
    final allRecords = _historyService.allRecords;
    final filteredRecords = allRecords.where((r) {
      final now = DateTime.now();
      switch (_historyFilter) {
        case HistoryFilter.today:
          return r.startTime.year == now.year &&
              r.startTime.month == now.month &&
              r.startTime.day == now.day;
        case HistoryFilter.yesterday:
          final yest = now.subtract(const Duration(days: 1));
          return r.startTime.year == yest.year &&
              r.startTime.month == yest.month &&
              r.startTime.day == yest.day;
        case HistoryFilter.thisWeek:
          return now.difference(r.startTime).inDays <= 7;
        case HistoryFilter.thisMonth:
          return r.startTime.year == now.year && r.startTime.month == now.month;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: CityRideTheme.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills Row
            Row(
              children: HistoryFilter.values.map((filter) {
                final isSelected = _historyFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filter.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : CityRideTheme.textDark,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: CityRideTheme.historyAccent,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? CityRideTheme.historyAccent : CityRideTheme.dividerColor,
                    ),
                    onSelected: (_) => setState(() => _historyFilter = filter),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Summary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "COMPLETED TRIPS",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: CityRideTheme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "${filteredRecords.length} Trips Recorded",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: CityRideTheme.historyAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Completed Trip Log Cards
            if (filteredRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    "No completed trips recorded for this period.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CityRideTheme.textMuted,
                    ),
                  ),
                ),
              )
            else
              ...filteredRecords.map((trip) => _buildHistoryCard(trip)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(TripSummary trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTripDetailsModal(trip),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: CityRideTheme.historyAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          trip.routeCode,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip.busNumber,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CityRideTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: CityRideTheme.historyIconBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "✓ COMPLETED",
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: CityRideTheme.historyAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Full round trip route summary (Origin → Destination → Origin)
              Text(
                trip.routeSummary,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CityRideTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${trip.duration.inMinutes} min duration • ${trip.stopsCompleted} stops completed",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CityRideTheme.textMuted,
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(trip.startTime),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CityRideTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  // ===========================================================================
  // MODULAR CARDS (DRIVER PROFILE, VEHICLE, SAFETY CHECK, ROUTE, SCHEDULE, QUICK ACTIONS)
  // ===========================================================================


  // ===========================================================================
  // 3. COMPACT COLLAPSIBLE SAFETY CHECK MODULE (DISTINCT STATUS COLORS)
  // ===========================================================================


  void _showVehicleVerificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Verify Bus Registration",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: TextField(
          controller: _busController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: "e.g. KA06F8558",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _verifyBus();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _verifyBus();
            },
            style: ElevatedButton.styleFrom(backgroundColor: CityRideTheme.primaryGreen),
            child: const Text("VERIFY"),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODULE 1 — ROUTE MODULE (ALWAYS FIXED VISIBLE TEXT FIELD + VERIFIED INFO BELOW)
  // ===========================================================================
  Widget _buildRouteModule(
    bool isRouteVerified,
    TransitRoute? verifiedRoute,
  ) {
    final Color headerBg = isRouteVerified ? CityRideTheme.routeHeaderBg : const Color(0xFF064E3B);
    final Color border = isRouteVerified ? CityRideTheme.routeBorder : const Color(0xFF059669);
    final Color accentColor = isRouteVerified ? CityRideTheme.routeAccent : const Color(0xFF059669);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4.5, color: accentColor),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(color: headerBg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.alt_route_rounded, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "YOUR ROUTE",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    "Route selection & corridor",
                                    style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isRouteVerified ? const Color(0xFF10B981) : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.8),
                            ),
                            child: Text(
                              isRouteVerified ? "✓ VERIFIED" : "STEP 3",
                              style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: border),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Text Field & Quick Select Chips (ALWAYS VISIBLE & FIXED)
                          Text(
                            "Route Code",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CityRideTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _routeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                                  decoration: InputDecoration(
                                    hintText: "Enter Route Code (e.g. CR101)",
                                    hintStyle: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textLight),
                                    filled: true,
                                    fillColor: CityRideTheme.scaffoldBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  ),
                                  onSubmitted: (_) => _verifyRoute(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _tripEngine.isRouteValidating ? null : _verifyRoute,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CityRideTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 1,
                                ),
                                child: _tripEngine.isRouteValidating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        "VERIFY",
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Quick Select Tumakuru Route:",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: CityRideTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickRouteChip("CR101", "SIT Gate"),
                                _buildQuickRouteChip("CR102", "Siddaganga"),
                                _buildQuickRouteChip("CR103", "Melekote"),
                                _buildQuickRouteChip("CR201", "Kyathsandra"),
                                _buildQuickRouteChip("CR202", "Heggere"),
                                _buildQuickRouteChip("CR301", "Station Loop"),
                              ],
                            ),
                          ),
                          if (_tripEngine.routeError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _tripEngine.routeError!,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: CityRideTheme.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],

                          // 2. Verified Route Details (Displayed BELOW the still-visible text field)
                          if (isRouteVerified && verifiedRoute != null) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: CityRideTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        verifiedRoute.routeCode,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${verifiedRoute.stops.length} STOPS • ${verifiedRoute.totalDistanceKm} KM",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => _requestRouteChange(_tripEngine.resetRoute),
                                  child: Text(
                                    "CHANGE",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF047857),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              verifiedRoute.routePathDescription.isNotEmpty
                                  ? verifiedRoute.routePathDescription
                                  : "${verifiedRoute.origin} → ${verifiedRoute.destination}",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: CityRideTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRouteChip(String code, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: const Icon(Icons.alt_route_rounded, size: 14, color: CityRideTheme.primaryGreen),
        label: Text(
          "$code ($label)",
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF166534),
          ),
        ),
        backgroundColor: const Color(0xFFF0FDF4),
        side: const BorderSide(color: Color(0xFFBBF7D0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () {
          _requestRouteChange(() {
            _routeController.text = code;
            _verifyRoute();
          });
        },
      ),
    );
  }

  // ===========================================================================
  // MODULE 2 — ACTIVE / CURRENT TRIP MODULE (PROMINENT 2ND POSITION)
  // ===========================================================================
  Widget _buildActiveOrCurrentTripModule({
    required bool isTripActive,
    required bool isRouteVerified,
    required bool isBusVerified,
    required bool isInspectionPassed,
    required BusVehicle? verifiedBus,
    required TransitRoute? verifiedRoute,
  }) {
    // 1. Before safety check is completed: show existing info banner
    if (!isInspectionPassed) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                !isRouteVerified
                    ? "Enter and verify your route above to view trip details and schedule."
                    : "Complete vehicle verification and safety check on the Dashboard to start your trip.",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Safety check complete AND trip is active: reveal full ActiveTripHeroCard
    if (isTripActive) {
      final trip = _tripEngine.activeTrip;
      final route = trip?.route ?? verifiedRoute;
      final nextStop = _tripEngine.nextStop ?? _tripEngine.currentStop;
      final busNo = verifiedBus?.busNumber ?? 'KA06F8558';
      final totalStops = route?.stops.length ?? 11;
      final currentStopNum = (_tripEngine.currentStopIndex + 1).clamp(1, totalStops);

      final routeLine = "${route?.routeCode ?? 'CR101'} • ${route?.origin ?? 'CENTRAL'} → ${route?.destination ?? 'TUMAKURU'}";
      final int etaSec = _tripEngine.etaToNextStopSeconds;
      final String etaText = etaSec > 0 ? 'ETA ${(etaSec / 60).ceil().toString().padLeft(2, '0')} min' : 'ETA 06 min';
      final tripProgressText = "Trip ${currentStopNum > 1 ? currentStopNum : 3} of $totalStops";

      return ActiveTripHeroCard(
        isTripActive: true,
        statusText: "ON DUTY",
        headerTitle: "CURRENT TRIP",
        badgeText: "LIVE IN TRANSIT",
        routeLine: routeLine,
        busNumber: busNo,
        nextStopName: nextStop?.name ?? 'Tumakuru Bus Stand',
        etaText: etaText,
        punctualityText: "ON TIME",
        timeText: "08:42 AM",
        tripProgressText: tripProgressText,
        ctaText: "VIEW LIVE COCKPIT →",
        onOpenCurrentTrip: () => setState(() => _currentTabIndex = 2),
      );
    }

    // 3. Safety check complete BUT trip not started yet: lighter interim ready state
    final busNo = verifiedBus?.busNumber ?? 'KA06F8558';
    final routeCode = verifiedRoute?.routeCode ?? 'CR101';
    final routeName = verifiedRoute != null
        ? "${verifiedRoute.origin} → ${verifiedRoute.destination}"
        : "Central Bus Stand → Tumakuru";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "READY TO START",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "$routeCode • $busNo",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Ready to start — trip will appear here once you begin your first stop",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            routeName,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _handleStartTrip,
              icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
              label: Text(
                "START TRIP",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CityRideTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // MODULE 3 — TODAY'S UPCOMING SCHEDULE (UPCOMING TRIPS ONLY)
  // ===========================================================================
  Widget _buildUpcomingScheduleModule() {
    final driver = _authService.activeDriver;
    final driverId = driver?.id ?? 'DRV_001';
    final allSchedules = TransitCatalog.getSchedulesForDriver(driverId);
    final activeTrip = _tripEngine.activeTrip;
    final completedTrips = _tripEngine.completedTripsToday;

    // Filter out the active trip so this module shows only upcoming / next trips
    final upcomingSchedules = allSchedules.where((item) {
      final isItemActive = activeTrip != null &&
          activeTrip.status == TripStatus.active &&
          (activeTrip.route.routeCode == item.routeCode || activeTrip.id.contains(item.routeCode));
      return !isItemActive;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CityRideTheme.scheduleBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: CityRideTheme.scheduleAccent.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4.5, color: CityRideTheme.scheduleAccent),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: const BoxDecoration(color: CityRideTheme.scheduleHeaderBg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TODAY'S SCHEDULE",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    "Upcoming assigned trips",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.8),
                            ),
                            child: Text(
                              "${upcomingSchedules.length} UPCOMING",
                              style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: CityRideTheme.scheduleBorder),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: upcomingSchedules.map((item) {
                          final isItemCompleted = completedTrips.any((t) => t.routeCode == item.routeCode) || item.status == 'COMPLETED';

                          final Color itemBg = isItemCompleted ? const Color(0xFFF8FAFC) : Colors.white;
                          final Color itemBorder = isItemCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1);

                          return InkWell(
                            onTap: () {
                              if (!isItemCompleted) {
                                _routeController.text = item.routeCode;
                                _verifyRoute();
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: itemBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: itemBorder, width: 1.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECFDF5),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: const Color(0xFFBBF7D0)),
                                              ),
                                              child: Text(
                                                item.routeCode,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF065F46),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.scheduleCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: CityRideTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.routePathDescription.isNotEmpty
                                              ? item.routePathDescription
                                              : "${item.origin} → ${item.destination}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isItemCompleted ? const Color(0xFF64748B) : CityRideTheme.textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.plannedStartTime,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isItemCompleted ? const Color(0xFF64748B) : CityRideTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isItemCompleted ? const Color(0xFFF1F5F9) : const Color(0xFFFFFBEB),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isItemCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
                                          ),
                                        ),
                                        child: Text(
                                          isItemCompleted ? "✓ COMPLETED" : "UPCOMING",
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: isItemCompleted ? const Color(0xFF64748B) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // QUICK ACTIONS MODULE (PRIORITIZED: INCIDENT | ADMIN | SOS)
  // ===========================================================================
  Widget _buildPrioritizedQuickActionsModule() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A0F172A),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              "QUICK ACTIONS",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            children: [
              // Incident: Warning Amber (Alert priority)
              _buildPrioritizedActionTile(
                icon: Icons.warning_amber_rounded,
                label: "INCIDENT",
                subtitle: "Log Issue",
                bg: CityRideTheme.quickIncidentBg,
                border: CityRideTheme.quickIncidentBorder,
                fg: CityRideTheme.quickIncidentIcon,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ReportIncidentModal(),
                  );
                },
              ),
              const SizedBox(width: 8),
              // Dispatch: Calm Slate Neutral (Operational priority)
              _buildPrioritizedActionTile(
                icon: Icons.headset_mic_outlined,
                label: "DISPATCH",
                subtitle: "Admin",
                bg: CityRideTheme.quickAdminBg,
                border: CityRideTheme.quickAdminBorder,
                fg: CityRideTheme.quickAdminIcon,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ContactAdminScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              // SOS: High Urgency Emergency Red (Emergency priority)
              _buildPrioritizedActionTile(
                icon: Icons.emergency_rounded,
                label: "SOS",
                subtitle: "Hold 3s",
                bg: CityRideTheme.quickSosBg,
                border: CityRideTheme.quickSosBorder,
                fg: CityRideTheme.quickSosIcon,
                isEmergency: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritizedActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color bg,
    required Color border,
    required Color fg,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: isEmergency ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: fg.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: fg.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LIVE TRIP HEADER & NEXT STOP CARD (FOR PAGE 3)
  // ===========================================================================
  Widget _buildTripTelemetryHeader(
    bool isDark,
    DriverTrip? trip,
    TransitRoute? activeRoute,
    bool isGpsLive,
    int delayMinutes,
  ) {
    final leg = _tripEngine.legDirection;
    final isReturning = leg == TripLegDirection.returning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Group: Route Code, Direction, and Bus Registration (Responsive & Truncate Safe)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF047857) : CityRideTheme.lightGreenChip,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        activeRoute?.routeCode ?? "CR101",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : CityRideTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isReturning
                            ? (isDark ? const Color(0xFF3B1E54) : const Color(0xFFF3E8FF))
                            : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isReturning ? "RETURNING" : "OUTBOUND",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isReturning
                              ? (isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE))
                              : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        trip?.bus.busNumber ?? _tripEngine.verifiedBus?.busNumber ?? "KA06F8558",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : CityRideTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Right Group: GPS Status Badge & HUD Mode Toggle (Compact, no overflow)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GpsStatusBadge(isLive: isGpsLive, isDark: isDark),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 18,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DelayStatusBadge(delayMinutes: delayMinutes, isDark: isDark),
              Text(
                "LAT: ${_gpsService.latitude.toStringAsFixed(4)}  LON: ${_gpsService.longitude.toStringAsFixed(4)}",
                style: GoogleFonts.inter(
                  fontSize: 10.5,
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

  // ===========================================================================
  // LIVE TRIP ACTION DOCK (END TRIP | INCIDENT | SOS)
  // ===========================================================================
  Widget _buildTripBottomActionDock(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? CityRideTheme.cockpitBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // END TRIP (Operational Stop)
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: _handleEndTrip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CityRideTheme.errorColor,
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  "END TRIP",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // INCIDENT (Log Issue)
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ReportIncidentModal(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFBEB),
                  foregroundColor: const Color(0xFFD97706),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFDE68A), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  "INCIDENT",
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // SOS BUTTON (Urgent Emergency with 3s hold gesture)
          Expanded(
            child: SizedBox(
              height: 44,
              child: SosHoldButton(
                onSosTriggered: _handleSosTrigger,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStopCard(
    bool isDark,
    TransitStop? currentStop,
    TransitStop? nextStop,
    TransitRoute? activeRoute,
    bool isTripActive,
  ) {
    final targetStop = nextStop ?? currentStop;
    final etaSeconds = _tripEngine.etaToNextStopSeconds;
    final distMeters = _tripEngine.distanceToNextStopMeters;

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
                    const Icon(Icons.directions_bus_rounded, size: 13, color: CityRideTheme.primaryGreen),
                    const SizedBox(width: 5),
                    Text(
                      "NEXT STOP",
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: CityRideTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      "ETA: ${(etaSeconds / 60).ceil()} MIN",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            targetStop?.name ?? "KSRTC Bus Stand",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : CityRideTheme.textDark,
              letterSpacing: -0.3,
            ),
          ),
          if (targetStop?.kannadaName != null && targetStop!.kannadaName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              targetStop.kannadaName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Distance: ${(distMeters / 1000).toStringAsFixed(1)} km (${distMeters.round()} m)",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _tripEngine.manualAdvanceToNextStop(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                label: const Text("ARRIVED AT STOP"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTripDetailsModal(TripSummary summary) {
    final startTimeStr = DateFormat('hh:mm a, dd MMM').format(summary.startTime);
    final endTimeStr = DateFormat('hh:mm a, dd MMM').format(summary.endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Trip Details",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CityRideTheme.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CityRideTheme.lightGreenChip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    summary.busNumber,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: CityRideTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "${summary.routeCode} • ${summary.routeName}",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
            ),
            const SizedBox(height: 16),
            const Divider(color: CityRideTheme.dividerColor),
            const SizedBox(height: 12),
            _buildModalRow("Trip ID", summary.tripId),
            _buildModalRow("Route Path", summary.routeSummary),
            _buildModalRow("Started", startTimeStr),
            _buildModalRow("Completed", endTimeStr),
            _buildModalRow("Total Duration", "${summary.duration.inMinutes} mins"),
            _buildModalRow("Stops Completed", "${summary.stopsCompleted} / ${summary.totalStops}"),
            _buildModalRow("Delay Status", summary.delayMinutes == 0 ? "On Time" : "+${summary.delayMinutes} mins"),
            _buildModalRow("Incidents Logged", "${summary.incidentsCount}"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  "CLOSE",
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
