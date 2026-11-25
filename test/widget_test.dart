import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cityride_driver_panel/core/constants/transit_catalog.dart';
import 'package:cityride_driver_panel/core/theme/app_theme.dart';
import 'package:cityride_driver_panel/core/utils/geo_utils.dart';
import 'package:cityride_driver_panel/core/utils/validators.dart';
import 'package:cityride_driver_panel/models/inspection_models.dart';
import 'package:cityride_driver_panel/models/trip_models.dart';
import 'package:cityride_driver_panel/models/vehicle_model.dart';
import 'package:cityride_driver_panel/screens/auth/driver_login_screen.dart';
import 'package:cityride_driver_panel/screens/dashboard/driver_dashboard_screen.dart';
import 'package:cityride_driver_panel/services/driver_auth_service.dart';
import 'package:cityride_driver_panel/services/emergency_sos_service.dart';
import 'package:cityride_driver_panel/services/gps_service.dart';
import 'package:cityride_driver_panel/services/incident_service.dart';
import 'package:cityride_driver_panel/services/trip_engine.dart';
import 'package:cityride_driver_panel/services/trip_history_service.dart';
import 'package:cityride_driver_panel/widgets/active_trip_hero_card.dart';
import 'package:cityride_driver_panel/widgets/bus_vehicle_card.dart';
import 'package:cityride_driver_panel/widgets/trip_action_card.dart';
import 'package:cityride_driver_panel/widgets/driver_summary_grid.dart';
import 'package:cityride_driver_panel/widgets/driver_header.dart';
import 'package:cityride_driver_panel/widgets/live_driver_map.dart';
import 'package:cityride_driver_panel/widgets/route_timeline_widget.dart';
import 'package:cityride_driver_panel/widgets/shift_summary_card.dart';
import 'package:cityride_driver_panel/widgets/sos_hold_button.dart';
import 'package:cityride_driver_panel/widgets/today_stats_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CITYRIDE Driver Panel - Full System & State Machine Tests', () {
    test('GeoUtils distance, bearing and geofencing calculation', () {
      // KSRTC Stand (13.3395, 77.1005) to Ashoka Road (13.3360, 77.1042)
      final distMeters = GeoUtils.distanceBetweenMeters(13.3395, 77.1005, 13.3360, 77.1042);
      expect(distMeters, greaterThan(300));
      expect(distMeters, lessThan(800));

      final bearing = GeoUtils.calculateBearing(13.3395, 77.1005, 13.3360, 77.1042);
      expect(bearing, greaterThan(90));
      expect(bearing, lessThan(180));

      // Geofence check: point at 10m is inside 50m geofence
      final isInside = GeoUtils.isInsideGeofence(13.3395, 77.1005, 13.33952, 77.10052, 50.0);
      expect(isInside, isTrue);

      // Geofence check: point at 500m is outside 50m geofence
      final isOutside = GeoUtils.isInsideGeofence(13.3395, 77.1005, 13.3440, 77.1050, 50.0);
      expect(isOutside, isFalse);
    });

    test(r'Validators enforces Route Code Regex (^[A-Z]{2}[0-9]{3}$)', () {
      expect(Validators.isValidRouteCode('CR101'), isTrue);
      expect(Validators.isValidRouteCode('cr101'), isTrue); // normalizes
      expect(Validators.isValidRouteCode('KA202'), isTrue);
      expect(Validators.isValidRouteCode('CR10'), isFalse); // too short
      expect(Validators.isValidRouteCode('CR1001'), isFalse); // too long
      expect(Validators.isValidRouteCode('101CR'), isFalse);
    });

    test('Validators enforces Bus Registration Numbers', () {
      expect(Validators.isValidBusNumber('KA06F8558'), isTrue);
      expect(Validators.isValidBusNumber('KA 06 F 8558'), isTrue); // normalizes
      expect(Validators.isValidBusNumber('KA06F1234'), isTrue);
      expect(Validators.isValidBusNumber('KA06'), isFalse); // invalid
    });

    test('Validators enforces Indian Mobile Number, Email, Licence & Password Security', () {
      expect(Validators.isValidIndianMobile('9845012345'), isTrue);
      expect(Validators.isValidIndianMobile('+91 98450 12345'), isTrue);
      expect(Validators.isValidIndianMobile('1234567890'), isFalse); // Does not start with 6-9
      expect(Validators.isValidIndianMobile('98450'), isFalse); // Too short

      expect(Validators.isValidEmail('driver@cityride.in'), isTrue);
      expect(Validators.isValidEmail('invalid-email'), isFalse);

      expect(Validators.isValidLicenceNumber('KA-06-2012-0048291'), isTrue);
      expect(Validators.isValidLicenceNumber('KA06'), isFalse);

      expect(Validators.isPasswordValid('Password123!'), isTrue);
      expect(Validators.isPasswordValid('pass'), isFalse);

      final strength = Validators.getPasswordStrength('CityRide@2026');
      expect(strength, greaterThanOrEqualTo(0.8));
    });

    test('DriverAuthService registers new driver and generates unique Driver ID', () async {
      final auth = DriverAuthService();
      final res = await auth.registerDriver(
        fullName: 'Basavaraj Patil',
        dateOfBirth: '1988-08-12',
        mobile: '9845088990',
        email: 'basavaraj.patil@cityride.in',
        address: 'Batawadi Cross, Tumakuru',
        city: 'Tumakuru',
        emergencyContactName: 'Geetha Patil (Spouse)',
        emergencyContactNumber: '9845077889',
        licenceNumber: 'KA-06-2014-0098765',
        licenceExpiry: '2029-08-11',
        experience: '5-10 Years',
        driverCategory: 'Heavy Passenger Vehicle (HPV)',
        depot: 'Tumakuru Central City Depot #1 (Ashoka Road)',
        password: 'Password@123',
      );

      expect(res.success, isTrue);
      expect(res.driverId?.startsWith('TUM-DRV-'), isTrue);
      expect(res.profile?.name, equals('Basavaraj Patil'));
      expect(res.profile?.accountStatus, equals('ACTIVE'));
    });

    test('DriverAuthService handles Password Reset and Account Status checks', () async {
      final auth = DriverAuthService();
      final resetOk = await auth.sendPasswordResetEmail('ramesh.gowda@cityride.in');
      expect(resetOk, isTrue);
    });

    test('DriverAuthService authenticates valid Driver ID and PIN', () async {
      final auth = DriverAuthService();
      final success = await auth.login('TUM-DRV-1042', '1042');
      expect(success, isTrue);
      expect(auth.activeDriver?.name, equals('Ramesh Gowda'));
      expect(auth.activeDriver?.initials, equals('RG'));

      final fail = await auth.login('TUM-DRV-1042', '0000');
      expect(fail, isFalse);
    });

    test('PreTripInspection 6-item model handles standard checks and Other Issue', () {
      // 1. All standard pass with no other issue
      final clean = PreTripInspection.allPassed();
      expect(clean.isAllPassed, isTrue);
      expect(clean.hasIssues, isFalse);

      // 2. 5 standard pass but other issue flagged
      final withOther = clean.copyWith(
        otherIssuePresent: true,
        otherIssueDescription: 'Passenger door mechanism sticking',
      );
      expect(withOther.isAllPassed, isFalse);
      expect(withOther.hasIssues, isTrue);
    });

    test('TripEngine Full Sequential Workflow: Bus -> Inspection -> Route -> Trip -> Complete', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      // Reset for clean test run
      engine.startNewTripFlow();
      expect(engine.workflowState, equals(DriverWorkflowState.busRequired));

      // Step 1: Validate Bus Number
      final busOk = await engine.validateBusNumber('KA06F8558');
      expect(busOk, isTrue);
      expect(engine.isBusVerified, isTrue);
      expect(engine.verifiedBus?.busNumber, equals('KA06F8558'));

      // Step 2: Complete Pre-Trip 5-point inspection + Other issue checked
      engine.passAllInspection();
      expect(engine.isInspectionPassed, isTrue);
      expect(engine.workflowState, equals(DriverWorkflowState.inspectionCompleted));

      // Step 3: Validate Route Code
      final routeOk = await engine.validateRouteCode('CR101');
      expect(routeOk, isTrue);
      expect(engine.isRouteVerified, isTrue);
      expect(engine.verifiedRoute?.routeCode, equals('CR101'));
      expect(engine.isReadyToStart, isTrue);

      // Step 4: Start Active Trip
      final started = engine.startTrip();
      expect(started, isTrue);
      expect(engine.isTripActive, isTrue);
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));

      // Persistent across UI navigation: activeTrip remains alive
      expect(engine.activeTrip, isNotNull);
      expect(engine.activeTrip?.route.routeCode, equals('CR101'));

      // Step 5: Simulate bus traveling through sequential stops -> Destination Reached
      final totalStops = engine.activeTrip!.route.stops.length;
      expect(totalStops, greaterThanOrEqualTo(6));

      // Progress through each stop in sequence
      for (final stop in engine.activeTrip!.route.stops) {
        GpsService().setManualPosition(
          stop.latitude,
          stop.longitude,
          speed: 0.0,
        );
      }

      // Verify trip transitions safely to destinationReached and activeTrip is cleared
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.isTripActive, isFalse);
      expect(engine.lastCompletedSummary, isNotNull);
      expect(engine.lastCompletedSummary?.routeCode, equals('CR101'));
      expect(engine.lastCompletedSummary?.stopsCompleted, equals(totalStops));

      // Duplicate completion events should be safely ignored
      final finalStop = TransitCatalog.cr101Stops.last;
      GpsService().setManualPosition(
        finalStop.latitude,
        finalStop.longitude,
        speed: 0.0,
      );
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));

      // Step 6: Start New Trip resets bus requirement
      engine.startNewTripFlow();
      expect(engine.workflowState, equals(DriverWorkflowState.busRequired));
      expect(engine.isBusVerified, isFalse);
      expect(engine.isInspectionPassed, isFalse);
    });

    test('TripHistoryService filters trips by timeframe', () {
      final history = TripHistoryService();
      history.setFilter(HistoryFilter.today);
      expect(history.currentFilter, equals(HistoryFilter.today));
      expect(history.filteredRecords.isNotEmpty, isTrue);

      history.setFilter(HistoryFilter.thisWeek);
      expect(history.filteredRecords.length, greaterThanOrEqualTo(1));
    });

    test('IncidentService logs incidents with reference codes', () async {
      final incService = IncidentService();
      final incident = await incService.submitIncident(
        incidentType: 'Traffic Block',
        description: 'Road diversion near Town Hall Circle',
      );

      expect(incident, isNotNull);
      expect(incident?.incidentCode.startsWith('INC-'), isTrue);
      expect(incService.incidents.any((i) => i.incidentCode == incident?.incidentCode), isTrue);
    });

    test('EmergencySosService broadcasts alert without audio siren', () async {
      final sos = EmergencySosService();
      await sos.triggerSos(
        tripId: 'TRIP_TEST_SOS',
        vehicleId: 'KA06F8558',
        routeId: 'ROUTE_CR101',
        routeName: 'Route 1',
      );

      expect(sos.isSosActive, isTrue);
      expect(sos.activeSos?.vehicleReg, equals('KA06F8558'));
      expect(sos.contacts.isNotEmpty, isTrue);

      sos.resolveSos(notes: 'Test completed safely');
      expect(sos.isSosActive, isFalse);
    });

    test('CityRideTheme defines consistent module accent colors', () {
      expect(CityRideTheme.vehicleAccent, isNotNull);
      expect(CityRideTheme.safetyAccent, isNotNull);
      expect(CityRideTheme.routeAccent, isNotNull);
      expect(CityRideTheme.scheduleAccent, isNotNull);
      expect(CityRideTheme.historyAccent, isNotNull);
      expect(CityRideTheme.quickActionsAccent, isNotNull);

      // Verify that Schedule (Teal) and History (Steel Blue) have distinct accents
      expect(CityRideTheme.scheduleAccent, equals(const Color(0xFF0F766E)));
      expect(CityRideTheme.scheduleAccent, isNot(equals(CityRideTheme.historyAccent)));
      expect(CityRideTheme.vehicleAccent, equals(const Color(0xFF05684B)));

      // Verify Bold Solid Fill Header Tokens
      expect(CityRideTheme.workflowHeaderBg, equals(const Color(0xFF0F766E)));
      expect(CityRideTheme.vehicleHeaderBg, equals(const Color(0xFF065F46)));
      expect(CityRideTheme.safetyHeaderBg, equals(const Color(0xFF8D5B18)));
      expect(CityRideTheme.routeHeaderBg, equals(const Color(0xFF064E3B)));
      expect(CityRideTheme.scheduleHeaderBg, equals(const Color(0xFF0F766E)));
      expect(CityRideTheme.historyHeaderBg, equals(const Color(0xFF0369A1)));
      expect(CityRideTheme.quickActionsHeaderBg, equals(const Color(0xFF115E59)));
    });

    testWidgets('DriverLoginScreen excludes registration card and retains login & demo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DriverLoginScreen(),
        ),
      );
      await tester.pump();

      // Expect login elements
      expect(find.text('DRIVER LOGIN'), findsOneWidget);
      expect(find.text('LOGIN TO CONSOLE'), findsOneWidget);
      expect(find.text('DEMO / DEVELOPMENT ONLY'), findsOneWidget);

      // Verify that the registration section is completely removed
      expect(find.text('NEW DRIVER?'), findsNothing);
      expect(find.text('CREATE DRIVER ACCOUNT'), findsNothing);
      expect(find.text('Register to access the CityRide Driver Console'), findsNothing);
    });

    testWidgets('SosHoldButton and Bottom Action Row fit narrow mobile screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text("REPORT\nINCIDENT"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 50,
                      child: SosHoldButton(
                        onSosTriggered: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Ensure no layout overflow errors occurred
      expect(tester.takeException(), isNull);
      expect(find.text("REPORT\nINCIDENT"), findsOneWidget);
      expect(find.text("PRESS & HOLD\nEMERGENCY SOS (3s)"), findsOneWidget);
    });

    testWidgets('RouteTimelineWidget renders two-sided timeline with Kannada stop names and live badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RouteTimelineWidget(
                stops: TransitCatalog.cr101Stops,
                currentStopIndex: 1, // Ashoka Road Circle is current
                isDark: false,
                delayMinutes: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Expect Column sub-headers
      expect(find.text('ARR / ETA'), findsOneWidget);
      expect(find.text('STOPS & SEQUENCE'), findsOneWidget);
      expect(find.text('DEPART'), findsOneWidget);

      // Expect stop names in uppercase (round trip contains them twice)
      expect(find.text('ASHOKA ROAD CIRCLE'), findsNWidgets(2));
      expect(find.text('TOWN HALL TUMAKURU'), findsNWidgets(2));

      // Expect Kannada stop names (outbound and return)
      expect(find.text('ಅಶೋಕ ರಸ್ತೆ ವೃತ್ತ'), findsOneWidget);
      expect(find.text('ಅಶೋಕ ರಸ್ತೆ ವೃತ್ತ (ವಾಪಸ್)'), findsOneWidget);
      expect(find.text('ಟೌನ್ ಹಾಲ್ ತುಮಕೂರು'), findsOneWidget);
      expect(find.text('ಟೌನ್ ಹಾಲ್ ತುಮಕೂರು (ವಾಪಸ್)'), findsOneWidget);

      // Expect Live current stop badge
      expect(find.text('BUS HERE (LIVE)'), findsOneWidget);

      // Expect Next stop badge
      expect(find.text('NEXT STOP'), findsOneWidget);
    });

    test('TripEngine Round-Trip Multi-Stop Flow: KSRTC -> SIT Back -> SIT Main -> KSRTC Return', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      // Reset
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR102');

      expect(engine.isReadyToStart, isTrue);
      expect(engine.verifiedRoute?.stops.length, equals(5));
      expect(engine.verifiedRoute?.stops[0].name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.stops[1].name, equals('SIT Main Gate'));
      expect(engine.verifiedRoute?.stops[2].name, equals('SIT Back Gate'));
      expect(engine.verifiedRoute?.stops[3].name, equals('SIT Main Gate'));
      expect(engine.verifiedRoute?.stops[4].name, equals('KSRTC Bus Stand'));

      // Start Trip at Stop 0
      final started = engine.startTrip();
      expect(started, isTrue);
      expect(engine.currentStopIndex, equals(0));
      expect(engine.legDirection, equals(TripLegDirection.outbound));

      // Move to Stop 1: SIT Main Gate (Intermediate Outbound)
      final sitMain = engine.verifiedRoute!.stops[1];
      GpsService().setManualPosition(sitMain.latitude, sitMain.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));
      expect(engine.isTripActive, isTrue); // MUST NOT BE COMPLETED!
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));

      // Move to Stop 2: SIT Back Gate (Outbound Turnaround)
      final sitBack = engine.verifiedRoute!.stops[2];
      GpsService().setManualPosition(sitBack.latitude, sitBack.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(2));
      expect(engine.legDirection, equals(TripLegDirection.returning));
      expect(engine.isTripActive, isTrue); // MUST NOT BE COMPLETED!
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));

      // Move to Stop 3: SIT Main Gate (Intermediate Return Leg)
      final sitMainReturn = engine.verifiedRoute!.stops[3];
      GpsService().setManualPosition(sitMainReturn.latitude, sitMainReturn.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(3));
      expect(engine.legDirection, equals(TripLegDirection.returning));
      expect(engine.isTripActive, isTrue); // MUST NOT BE COMPLETED!
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));

      // Move to Stop 4: KSRTC Bus Stand (Final Return Destination)
      final ksrtcReturn = engine.verifiedRoute!.stops[4];
      GpsService().setManualPosition(ksrtcReturn.latitude, ksrtcReturn.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(4));
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.lastCompletedSummary, isNotNull);
      expect(engine.lastCompletedSummary?.stopsCompleted, equals(5));
      expect(engine.lastCompletedSummary?.origin, equals('KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary?.destination, equals('KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary?.routeSummary, equals('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'));

      // Tap Back to Dashboard
      engine.finishTripAndReturnToDashboard();
      expect(engine.activeTrip, isNull);
      expect(engine.isTripActive, isFalse);
    });

    test('Scenario 1: Verifying CR101 then changing to CR102 does not show CR102 as completed', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();

      // Verify CR101 without starting
      await engine.validateRouteCode('CR101');
      expect(engine.isRouteVerified, isTrue);
      expect(engine.verifiedRoute?.routeCode, equals('CR101'));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.currentStopIndex, equals(0));

      // Change route to CR102
      await engine.validateRouteCode('CR102');
      expect(engine.isRouteVerified, isTrue);
      expect(engine.verifiedRoute?.routeCode, equals('CR102'));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary, isNull);
    });

    test('Scenario 2: Completing CR101 then selecting CR102 starts fresh from first stop', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      // Complete all stops of CR101
      for (final stop in engine.activeTrip!.route.stops) {
        GpsService().setManualPosition(stop.latitude, stop.longitude, speed: 0.0);
      }
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.lastCompletedSummary?.routeCode, equals('CR101'));

      // Return to dashboard
      engine.finishTripAndReturnToDashboard();
      expect(engine.activeTrip, isNull);
      expect(engine.verifiedRoute, isNull);

      // Now verify new route CR102
      await engine.validateRouteCode('CR102');
      expect(engine.verifiedRoute?.routeCode, equals('CR102'));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary, isNull);
    });

    test('Scenario 3: Changing route during active trip stops old trip and resets to Stop 0', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      // Advance sequentially to Stop 1 (Ashoka Road) and Stop 2 (Town Hall)
      final stop1 = engine.verifiedRoute!.stops[1];
      GpsService().setManualPosition(stop1.latitude, stop1.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));

      final stop2 = engine.verifiedRoute!.stops[2];
      GpsService().setManualPosition(stop2.latitude, stop2.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(2));
      expect(engine.isTripActive, isTrue);

      // Reset and change route to CR103
      engine.cancelActiveTripAndResetRoute();
      expect(engine.isTripActive, isFalse);
      expect(engine.activeTrip, isNull);

      await engine.validateRouteCode('CR103');
      expect(engine.verifiedRoute?.routeCode, equals('CR103'));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));
    });

    test('Scenario 4: Intermediate stops and outbound turnaround do NOT complete trip, only final return stop completes it', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      final stops = engine.verifiedRoute!.stops;
      expect(stops.length, equals(11));

      // Stop 1: Ashoka Road
      GpsService().setManualPosition(stops[1].latitude, stops[1].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));
      expect(engine.isTripActive, isTrue);
      expect(engine.legDirection, equals(TripLegDirection.outbound));

      // Stop 2: Town Hall
      GpsService().setManualPosition(stops[2].latitude, stops[2].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(2));

      // Stop 3: SS Puram
      GpsService().setManualPosition(stops[3].latitude, stops[3].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(3));

      // Stop 4: SIT Main Gate (Outbound)
      GpsService().setManualPosition(stops[4].latitude, stops[4].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(4));
      expect(engine.isTripActive, isTrue);

      // Stop 5: SIT Back Gate (Outbound Turnaround - Midpoint)
      GpsService().setManualPosition(stops[5].latitude, stops[5].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(5));
      expect(engine.isTripActive, isTrue);
      expect(engine.legDirection, equals(TripLegDirection.returning)); // Direction switched to RETURNING
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive)); // Must NOT complete trip!

      // Stop 6: SIT Main Gate (Return)
      GpsService().setManualPosition(stops[6].latitude, stops[6].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(6));
      expect(engine.isTripActive, isTrue);

      // Stop 7: SS Puram Circle (Return)
      GpsService().setManualPosition(stops[7].latitude, stops[7].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(7));

      // Stop 8: Town Hall Tumakuru (Return)
      GpsService().setManualPosition(stops[8].latitude, stops[8].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(8));

      // Stop 9: Ashoka Road Circle (Return)
      GpsService().setManualPosition(stops[9].latitude, stops[9].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(9));
      expect(engine.isTripActive, isTrue);

      // Stop 10: KSRTC Bus Stand (Final Return Stop 11 of 11)
      GpsService().setManualPosition(stops[10].latitude, stops[10].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(10));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.lastCompletedSummary, isNotNull);
      expect(engine.lastCompletedSummary?.stopsCompleted, equals(11));
      expect(engine.lastCompletedSummary?.routeSummary, equals('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'));
    });

    test('Scenario 5: Dynamic stop sequence for CR101 (11 stops), CR102 (5 stops), CR103 (5 stops)', () async {
      final engine = TripEngine();

      await engine.validateRouteCode('CR101');
      expect(engine.verifiedRoute?.stops.length, equals(11));
      expect(engine.verifiedRoute?.stops.first.name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.stops[5].name, equals('SIT Back Gate'));
      expect(engine.verifiedRoute?.stops.last.name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.routeSummary, equals('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'));

      await engine.validateRouteCode('CR102');
      expect(engine.verifiedRoute?.stops.length, equals(5));
      expect(engine.verifiedRoute?.stops.first.name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.stops[2].name, equals('SIT Back Gate'));
      expect(engine.verifiedRoute?.stops.last.name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.routeSummary, equals('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'));

      await engine.validateRouteCode('CR103');
      expect(engine.verifiedRoute?.stops.length, equals(5));
      expect(engine.verifiedRoute?.stops.first.name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.stops[2].name, equals('Melekote Cross'));
      expect(engine.verifiedRoute?.stops.last.name, equals('KSRTC Bus Stand'));
      expect(engine.verifiedRoute?.routeSummary, equals('KSRTC Bus Stand → Melekote Cross → KSRTC Bus Stand'));
    });

    test('Scenario 6: Trip lifecycle state transitions correctly', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      // NOT_STARTED
      engine.startNewTripFlow();
      expect(engine.workflowState, equals(DriverWorkflowState.busRequired));

      // Bus & Inspection verified
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();

      // READY_FOR_DEPARTURE (routeVerified)
      await engine.validateRouteCode('CR102');
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.isReadyToStart, isTrue);

      // IN_PROGRESS
      engine.startTrip();
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));
      expect(engine.legDirection, equals(TripLegDirection.outbound));

      // Stop 1: SIT Main Gate
      final sitMain = engine.verifiedRoute!.stops[1];
      GpsService().setManualPosition(sitMain.latitude, sitMain.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));

      // Stop 2: SIT Back Gate (Outbound Turnaround)
      final sitBack = engine.verifiedRoute!.stops[2];
      GpsService().setManualPosition(sitBack.latitude, sitBack.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(2));
      expect(engine.legDirection, equals(TripLegDirection.returning));
      expect(engine.workflowState, equals(DriverWorkflowState.tripActive));

      // Stop 3: SIT Main Gate (Return)
      final sitMainReturn = engine.verifiedRoute!.stops[3];
      GpsService().setManualPosition(sitMainReturn.latitude, sitMainReturn.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(3));
      expect(engine.legDirection, equals(TripLegDirection.returning));

      // Stop 4: COMPLETED (KSRTC Bus Stand Return)
      final returnStop = engine.verifiedRoute!.stops[4];
      GpsService().setManualPosition(returnStop.latitude, returnStop.longitude, speed: 0.0);
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.lastCompletedSummary, isNotNull);
      expect(engine.lastCompletedSummary?.stopsCompleted, equals(5));
      expect(engine.lastCompletedSummary?.routeSummary, equals('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'));
    });

    test('Scenario 7: Destination reached is strictly guarded by active trip and last stop index', () async {
      final engine = TripEngine();

      // Inactive route verification must never be destinationReached
      await engine.validateRouteCode('CR101');
      expect(engine.workflowState, isNot(equals(DriverWorkflowState.destinationReached)));
      expect(engine.lastCompletedSummary, isNull);
    });

    test('Scenario 8: Schedule and history isolation - route verification without starting does not add history', () async {
      final history = TripHistoryService();
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      final initialHistoryCount = history.allRecords.length;

      // Verify route without starting
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');

      // History count must remain unchanged
      expect(history.allRecords.length, equals(initialHistoryCount));
    });

    test('Scenario 9: Persistent dashboard navigation retains live active trip and current stop index', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      // Advance sequentially to Stop 3 (SS Puram)
      for (int i = 1; i <= 3; i++) {
        final st = engine.verifiedRoute!.stops[i];
        GpsService().setManualPosition(st.latitude, st.longitude, speed: 0.0);
      }
      expect(engine.currentStopIndex, equals(3));
      expect(engine.isTripActive, isTrue);

      // Simulating driver navigating back to Dashboard
      // The active trip must remain active and at stop index 3
      expect(engine.isTripActive, isTrue);
      expect(engine.currentStopIndex, equals(3));
      expect(engine.currentStop?.name, equals('SS Puram Circle'));
      expect(engine.activeTrip?.route.routeCode, equals('CR101'));
    });

    test('Scenario 10: Strict Driver Data Isolation across login / logout', () async {
      final auth = DriverAuthService();
      final engine = TripEngine();
      final history = TripHistoryService();

      // 1. Driver A (Ramesh) logs in and starts a trip
      await auth.login('TUM-DRV-1042', '1042');
      expect(auth.activeDriver?.id, equals('DRV_001'));
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR102');
      engine.startTrip();

      expect(engine.isTripActive, isTrue);
      expect(engine.activeTrip?.driverId, equals('DRV_001'));
      expect(history.allRecords.every((r) => r.driverId == 'DRV_001'), isTrue);

      // 2. Driver A logs out
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.activeDriver, isNull);
      expect(engine.activeTrip, isNull);
      expect(engine.isTripActive, isFalse);
      expect(history.allRecords, isEmpty);

      // 3. Driver B (Siddaraju) logs in
      await auth.login('TUM-DRV-1088', '1088');
      expect(auth.isAuthenticated, isTrue);
      expect(auth.activeDriver?.id, equals('DRV_002'));
      expect(auth.activeDriver?.name, equals('Siddaraju M.'));

      // Driver B must NOT see Driver A's active trip
      expect(engine.activeTrip, isNull);
      expect(engine.isTripActive, isFalse);
      expect(history.allRecords.every((r) => r.driverId == 'DRV_002'), isTrue);

      // Driver B schedules must belong to Driver B
      final driverBSchedules = TransitCatalog.getSchedulesForDriver('DRV_002');
      expect(driverBSchedules.length, equals(2));
      expect(driverBSchedules.first.routeCode, equals('CR103'));
    });

    test('Test A: Selecting CR103 after CR102 is READY_FOR_DEPARTURE and never Destination Reached', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();

      // First select CR102
      await engine.validateRouteCode('CR102');
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));

      // Then change to CR103
      await engine.validateRouteCode('CR103');
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.isTripActive, isFalse);
      expect(engine.activeTrip, isNull);
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary, isNull);
      expect(engine.workflowState, isNot(equals(DriverWorkflowState.destinationReached)));
    });

    test('Test B: Selecting CR103 and doing nothing keeps status NOT_STARTED / READY_FOR_DEPARTURE', () async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');

      // Wait / idle
      await Future.delayed(const Duration(milliseconds: 50));

      expect(engine.isTripActive, isFalse);
      expect(engine.activeTrip, isNull);
      expect(engine.workflowState, equals(DriverWorkflowState.routeVerified));
      expect(engine.lastCompletedSummary, isNull);
    });

    test('Test C: Pressing START TRIP on CR103 transitions to IN_PROGRESS with first stop', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');

      expect(engine.isTripActive, isFalse);
      final started = engine.startTrip();
      expect(started, isTrue);
      expect(engine.isTripActive, isTrue);
      expect(engine.activeTrip?.status, equals(TripStatus.active));
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));
      expect(engine.nextStop?.name, equals('Batawadi Circle'));
    });

    test('Test D & E: Returning to dashboard and continuing active trip retains current stop', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');
      engine.startTrip();

      // Move to Stop 1 (Batawadi Circle)
      final stop1 = engine.verifiedRoute!.stops[1];
      GpsService().setManualPosition(stop1.latitude, stop1.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));
      expect(engine.currentStop?.name, equals('Batawadi Circle'));

      // Dashboard view retains active trip
      expect(engine.isTripActive, isTrue);
      expect(engine.currentStopIndex, equals(1));

      // Continuing trip retains same stop
      expect(engine.currentStop?.name, equals('Batawadi Circle'));
      expect(engine.nextStop?.name, equals('Melekote Cross'));
    });

    test('Test F: END TRIP manually ends trip without marking COMPLETED', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');
      engine.startTrip();

      expect(engine.isTripActive, isTrue);

      // Driver presses END TRIP
      engine.endTripEarly(reason: 'Driver ended early');
      expect(engine.isTripActive, isFalse);
      expect(engine.activeTrip, isNull);
      expect(engine.lastCompletedSummary, isNull);
      expect(engine.workflowState, isNot(equals(DriverWorkflowState.destinationReached)));
    });

    test('Test G: Complete full round trip on CR103', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');
      engine.startTrip();

      final stops = engine.verifiedRoute!.stops;
      expect(stops.length, equals(5));

      // Stop 1: Batawadi Circle
      GpsService().setManualPosition(stops[1].latitude, stops[1].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));
      expect(engine.isTripActive, isTrue);

      // Stop 2: Melekote Cross (Outbound Turnaround)
      GpsService().setManualPosition(stops[2].latitude, stops[2].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(2));
      expect(engine.legDirection, equals(TripLegDirection.returning));
      expect(engine.isTripActive, isTrue);

      // Stop 3: Batawadi Circle (Return leg)
      GpsService().setManualPosition(stops[3].latitude, stops[3].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(3));
      expect(engine.legDirection, equals(TripLegDirection.returning));
      expect(engine.isTripActive, isTrue);

      // Stop 4: KSRTC Bus Stand (Final Return Stop)
      GpsService().setManualPosition(stops[4].latitude, stops[4].longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(4));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.lastCompletedSummary, isNotNull);
      expect(engine.lastCompletedSummary?.stopsCompleted, equals(5));
      expect(engine.lastCompletedSummary?.routeSummary, equals('KSRTC Bus Stand → Melekote Cross → KSRTC Bus Stand'));
    });

    test('Test H: Changing route while active stops old trip and starts new route fresh', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR103');
      engine.startTrip();

      // Progress to Stop 1
      final stop1 = engine.verifiedRoute!.stops[1];
      GpsService().setManualPosition(stop1.latitude, stop1.longitude, speed: 0.0);
      expect(engine.currentStopIndex, equals(1));

      // Change to CR101
      engine.cancelActiveTripAndResetRoute();
      await engine.validateRouteCode('CR101');

      expect(engine.verifiedRoute?.routeCode, equals('CR101'));
      expect(engine.isTripActive, isFalse);
      expect(engine.currentStopIndex, equals(0));
      expect(engine.currentStop?.name, equals('KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary, isNull);
    });

    testWidgets('Test I: LiveDriverMap renders graceful fallback when stops are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveDriverMap(
              stops: [],
              currentLat: 13.3395,
              currentLon: 77.1005,
              headingDegrees: 0.0,
              currentStopIndex: 0,
            ),
          ),
        ),
      );

      expect(find.text('LIVE TRANSIT ROUTE'), findsOneWidget);
      expect(find.text('Map temporarily unavailable.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    test('Test J: CR101 complete round trip with 11 sequential stops and turnaround transition', () async {
      final engine = TripEngine();
      final auth = DriverAuthService();
      await auth.login('TUM-DRV-1042', '1042');

      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      final route = engine.verifiedRoute!;
      expect(route.stops.length, equals(11));

      // Verify each stop in the 11-stop sequence
      expect(route.stops[0].name, equals('KSRTC Bus Stand'));
      expect(route.stops[1].name, equals('Ashoka Road Circle'));
      expect(route.stops[2].name, equals('Town Hall Tumakuru'));
      expect(route.stops[3].name, equals('SS Puram Circle'));
      expect(route.stops[4].name, equals('SIT Main Gate'));
      expect(route.stops[5].name, equals('SIT Back Gate'));
      expect(route.stops[6].name, equals('SIT Main Gate'));
      expect(route.stops[7].name, equals('SS Puram Circle'));
      expect(route.stops[8].name, equals('Town Hall Tumakuru'));
      expect(route.stops[9].name, equals('Ashoka Road Circle'));
      expect(route.stops[10].name, equals('KSRTC Bus Stand'));

      // Progress through stops 1 to 5
      for (int i = 1; i <= 5; i++) {
        final st = route.stops[i];
        GpsService().setManualPosition(st.latitude, st.longitude, speed: 0.0);
      }

      // At SIT Back Gate (Stop index 5): Outbound Turnaround
      expect(engine.currentStopIndex, equals(5));
      expect(engine.currentStop?.name, equals('SIT Back Gate'));
      expect(engine.nextStop?.name, equals('SIT Main Gate'));
      expect(engine.legDirection, equals(TripLegDirection.returning));
      expect(engine.isTripActive, isTrue); // Not completed!

      // Progress through return stops 6 to 10
      for (int i = 6; i <= 10; i++) {
        final st = route.stops[i];
        GpsService().setManualPosition(st.latitude, st.longitude, speed: 0.0);
      }

      // At Stop 10 (KSRTC Bus Stand): Trip Completed
      expect(engine.currentStopIndex, equals(10));
      expect(engine.isTripActive, isFalse);
      expect(engine.workflowState, equals(DriverWorkflowState.destinationReached));
      expect(engine.lastCompletedSummary?.routeSummary, equals('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'));
      expect(engine.lastCompletedSummary?.stopsCompleted, equals(11));
    });

    testWidgets('Test K: RouteTimelineWidget renders complete 11-stop sequence with correct direction badges', (WidgetTester tester) async {
      final stops = TransitCatalog.cr101Stops;
      expect(stops.length, equals(11));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RouteTimelineWidget(
                stops: stops,
                currentStopIndex: 0,
              ),
            ),
          ),
        ),
      );

      // Verify headers & badges rendered
      expect(find.text('STOPS & SEQUENCE'), findsOneWidget);
      expect(find.text('BUS HERE (LIVE)'), findsOneWidget);
      expect(find.text('NEXT STOP'), findsOneWidget);
      expect(find.text('OUTBOUND TURNAROUND'), findsOneWidget);
      expect(find.text('FINAL STOP'), findsOneWidget);
    });

    testWidgets('Test L: DriverDashboardScreen renders persistent 4-tab bottom navigation bar', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Top persistent header is visible
      expect(find.text('CITYRIDE'), findsOneWidget);
      expect(find.text('DRIVER'), findsOneWidget);

      // Bottom navigation bar contains all 4 tabs
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Page 1 (Dashboard) shows vehicle card, safety check, and quick actions
      expect(find.text('ASSIGNED BUS'), findsOneWidget);
      expect(find.text('SAFETY CHECK'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
    });

    testWidgets('Test M: Route tab keeps Route Code input visible at top before and after verification', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Switch to Tab 1 (Route)
      await tester.tap(find.text('Route'));
      await tester.pumpAndSettle();

      // Verify Route Code input is visible
      expect(find.text('Route Code'), findsOneWidget);
      expect(find.text('VERIFY'), findsOneWidget);
      expect(find.text('Quick Select Tumakuru Route:'), findsOneWidget);

      // Verify CR101
      await engine.validateRouteCode('CR101');
      await tester.pumpAndSettle();

      // Verify Route Code input is STILL visible at the top after verification
      expect(find.text('Route Code'), findsOneWidget);
      expect(find.text('VERIFY'), findsOneWidget);

      // And verified details appear below it
      expect(find.text('11 STOPS • 8.4 KM'), findsOneWidget);
      expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
      expect(find.text('READY TO START'), findsOneWidget);
      expect(find.text('START TRIP'), findsOneWidget);
    });

    testWidgets('Test N: Starting trip transitions to Page 3 (Trip) with live telemetry and bottom action dock', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Switch to Route tab
      await tester.tap(find.text('Route'));
      await tester.pumpAndSettle();

      // Tap START TRIP
      await tester.tap(find.text('START TRIP'));
      await tester.pumpAndSettle();

      // Verify live trip tracking components
      expect(engine.isTripActive, isTrue);
      expect(find.text('OUTBOUND'), findsOneWidget);
      expect(find.text('NEXT STOP'), findsWidgets);
      expect(find.text('ROUTE STOP SEQUENCE'), findsOneWidget);

      // Verify bottom action dock replaces normal nav bar
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.text('INCIDENT'), findsOneWidget);
      expect(find.byType(SosHoldButton), findsOneWidget);

      // Clean up timer
      engine.endTripEarly();
      await tester.pump();
    });

    testWidgets('Test O: Trip History tab displays full round-trip route summary', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      final history = TripHistoryService();

      history.addCompletedRecord(TripSummary(
        tripId: 'TRIP_TEST_001',
        busNumber: 'KA06F8558',
        routeCode: 'CR101',
        routeName: 'KSRTC Stand - SIT Back Gate Loop',
        origin: 'KSRTC Bus Stand',
        destination: 'SIT Back Gate',
        startLocation: 'KSRTC Bus Stand',
        outboundDestination: 'SIT Back Gate',
        returnLocation: 'KSRTC Bus Stand',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        duration: const Duration(minutes: 30),
        totalStops: 11,
        stopsCompleted: 11,
        stops: TransitCatalog.cr101Stops,
        delayMinutes: 0,
        incidentsCount: 0,
      ));

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify full round trip path is displayed
      expect(find.text('KSRTC Bus Stand → SIT Back Gate → KSRTC Bus Stand'), findsWidgets);
      expect(find.text('30 min duration • 11 stops completed'), findsWidgets);
      expect(find.text('✓ COMPLETED'), findsWidgets);
    });

    testWidgets('Test P: Safety check on dashboard defaults to compact summary and expands on tap', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Compact summary is visible
      expect(find.text('SAFETY CHECK'), findsOneWidget);
      expect(find.text('5/5 PASSED ✓'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Chips are collapsed by default
      expect(find.text('✓ Fuel OK'), findsNothing);

      // Tap on Details to expand
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Now the 6 inspection chips and Re-inspect button are visible
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Air'), findsOneWidget);
      expect(find.text('Brakes'), findsOneWidget);
      expect(find.text('Tyres'), findsOneWidget);
      expect(find.text('Lights'), findsOneWidget);
      expect(find.text('VIEW / RE-INSPECT'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
    });

    testWidgets('Test Q: Bottom navigation bar remains tappable and interactive when transient toast is shown', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Trigger disabled Trip tab tap to show SnackBar
      await tester.tap(find.text('Trip'));
      await tester.pump();

      // SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);

      // Bottom navigation tabs are still completely visible and tappable
      expect(find.text('Route'), findsOneWidget);
      await tester.tap(find.text('Route'));
      await tester.pumpAndSettle();

      // Successfully switched to Route tab
      expect(find.text('Route Code'), findsOneWidget);
    });

    testWidgets('Test R: Dashboard renders primary vehicle hero card, safety check, stats row, and quick actions', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Verify old Next Action banner is removed
      expect(find.text('OPEN TRIP'), findsNothing);

      // Verify Bus / Vehicle Hero Card is rendered first
      expect(find.text('ASSIGNED BUS'), findsOneWidget);
      expect(find.text('KA06F8558'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);

      // Verify Safety Check Card is rendered second
      expect(find.text('SAFETY CHECK'), findsOneWidget);

      // Verify Today Stats Row is rendered third
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Driving'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);

      // Verify Quick Actions is rendered fourth
      expect(find.text('QUICK ACTIONS'), findsOneWidget);

      // Clean up timer
      engine.endTripEarly();
      await tester.pump();
    });

    testWidgets('Test S: Device back navigation pops from inner tab to Dashboard (Tab 0)', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('COMPLETED TRIPS'), findsOneWidget);

      // Simulate native system back button press
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Successfully navigated back to Dashboard
      expect(find.text('ASSIGNED BUS'), findsOneWidget);
    });

    testWidgets('Test T: Live Trip screen maintains permanent 4-tab bottom navigation bar', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Tap Trip tab
      await tester.tap(find.text('Trip'));
      await tester.pumpAndSettle();

      // Live trip components exist
      expect(find.text('ROUTE STOP SEQUENCE'), findsOneWidget);
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.text('INCIDENT'), findsOneWidget);

      // 4-tab bottom navigation bar is still completely visible!
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Driver can tap History tab to view logs while trip continues
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('COMPLETED TRIPS'), findsOneWidget);
      expect(engine.isTripActive, isTrue);

      // Clean up
      engine.endTripEarly();
      await tester.pump();
    });

    testWidgets('Test U: Route page renders 3-module hierarchy (Route -> Current Trip -> Upcoming Schedule)', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      engine.passAllInspection();
      await engine.validateRouteCode('CR101');
      engine.startTrip();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // Switch to Route tab (Tab 1)
      await tester.tap(find.text('Route'));
      await tester.pumpAndSettle();

      // Module 1: YOUR ROUTE
      expect(find.text('YOUR ROUTE'), findsOneWidget);
      expect(find.text('VERIFY'), findsOneWidget);
      expect(find.text('Quick Select Tumakuru Route:'), findsOneWidget);

      // Module 2: CURRENT TRIP with Standout LIVE IN TRANSIT badge
      expect(find.text('CURRENT TRIP'), findsOneWidget);
      expect(find.text('LIVE IN TRANSIT'), findsOneWidget);
      expect(find.text('VIEW LIVE COCKPIT →'), findsOneWidget);

      // Module 3: TODAY'S SCHEDULE with upcoming trips
      expect(find.text("TODAY'S SCHEDULE"), findsOneWidget);
      expect(find.text('Upcoming assigned trips'), findsOneWidget);

      // Tapping VIEW LIVE COCKPIT transitions directly to Trip tab (Tab 2)
      await tester.tap(find.text('VIEW LIVE COCKPIT →'));
      await tester.pumpAndSettle();

      expect(find.text('ROUTE STOP SEQUENCE'), findsOneWidget);
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.text('INCIDENT'), findsOneWidget);

      // Clean up
      engine.endTripEarly();
      await tester.pump();
    });

    testWidgets('Test V: Profile tab is accessible via bottom navigation and top-right header shortcut', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pump();

      // 5 tabs exist in bottom navigation bar
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap Profile tab (Tab 4)
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify Profile page content is displayed
      expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
      expect(find.text('DRIVER INFORMATION'), findsOneWidget);
      expect(find.text('ACCOUNT & SECURITY'), findsOneWidget);
      expect(find.text('SIGN OUT'), findsOneWidget);

      // Back navigation from Profile tab pops to Dashboard
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('ASSIGNED BUS'), findsOneWidget);

      // Tapping top-right header avatar (initials RG) navigates to Profile tab
      await tester.tap(find.descendant(of: find.byType(DriverHeader), matching: find.text('RG')));
      await tester.pumpAndSettle();
      expect(find.text('PERSONAL INFORMATION'), findsOneWidget);
    });

    testWidgets('Test W: Today\'s Shift Summary card renders responsively without overflow on 360px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool setBusPressed = false;

      // 1. Unverified State with SET BUS button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ShiftSummaryCard(
                    isBusVerified: false,
                    onSetBus: () => setBusPressed = true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no overflow errors occurred
      expect(tester.takeException(), isNull);

      // Verify Shift Summary Card is rendered completely
      expect(find.text("TODAY'S SHIFT SUMMARY"), findsOneWidget);
      expect(find.text('ACTIVE SHIFT'), findsOneWidget);
      expect(find.text('Depot #1'), findsOneWidget);
      expect(find.text('SET BUS'), findsOneWidget);

      // Verify 3-stat grid cells
      expect(find.text('SHIFT START'), findsOneWidget);
      expect(find.text('07:30 AM'), findsOneWidget);
      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('2 Trips (16.8 km)'), findsOneWidget);
      expect(find.text('PUNCTUALITY'), findsOneWidget);
      expect(find.text('100% On Time'), findsOneWidget);

      // Verify SET BUS chip is interactive and triggers callback
      await tester.tap(find.text('SET BUS'));
      await tester.pumpAndSettle();
      expect(setBusPressed, isTrue);

      // 2. Verified State with long names
      bool resetBusPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ShiftSummaryCard(
                    isBusVerified: true,
                    onResetBus: () => resetBusPressed = true,
                    verifiedBus: const BusVehicle(id: 'v_1', busNumber: 'KA06F8558', model: 'Tata Starbus', capacity: 42),
                    verifiedRoute: const TransitRoute(
                      id: 'r_1',
                      routeCode: 'CR101',
                      routeName: 'Central Corridor - Tumakuru University Loop',
                      origin: 'KSRTC Bus Stand',
                      destination: 'SIT Campus',
                      totalDistanceKm: 8.4,
                      estimatedDurationMinutes: 30,
                      stops: [],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no overflow errors occurred even with long route name
      expect(tester.takeException(), isNull);
      expect(find.text('KA06F8558 • VERIFIED'), findsOneWidget);

      // Verify VERIFIED chip is tappable
      await tester.tap(find.text('KA06F8558 • VERIFIED'));
      await tester.pumpAndSettle();
      expect(resetBusPressed, isTrue);
    });

    testWidgets('Test X: Trip-focused Dashboard components render responsively without overflow on 360px width', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool openCurrentTripPressed = false;
      bool startShiftPressed = false;
      bool busCardPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Active Trip Card (Active state)
                      ActiveTripHeroCard(
                        isTripActive: true,
                        statusText: "ON DUTY",
                        routeLine: "CR101 • CENTRAL → TUMAKURU",
                        busNumber: "KA06F8558",
                        nextStopLabel: "NEXT STOP",
                        nextStopName: "Tumakuru Bus Stand",
                        etaText: "ETA 06 min",
                        punctualityText: "ON TIME",
                        timeText: "08:42 AM",
                        tripProgressText: "Trip 3 of 8",
                        ctaText: "OPEN CURRENT TRIP",
                        onOpenCurrentTrip: () => openCurrentTripPressed = true,
                      ),
                      const SizedBox(height: 16),

                      // Bus / Vehicle Card (NEW)
                      BusVehicleCard(
                        label: "ASSIGNED BUS",
                        busNumber: "KA06F8558",
                        assignmentInfo: "Depot #1 • Route CR101",
                        onTap: () => busCardPressed = true,
                      ),
                      const SizedBox(height: 16),

                      // Today's Stats Card (Simplified 2 columns)
                      const TodayStatsRow(
                        drivingTime: "2h 45m",
                        tripsCount: "3/8",
                      ),
                      const SizedBox(height: 16),

                      // Active Trip Card (Off-duty / Idle state)
                      ActiveTripHeroCard(
                        isTripActive: false,
                        onOpenCurrentTrip: () => startShiftPressed = true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure 0 overflow exceptions on 360px viewport
      expect(tester.takeException(), isNull);

      // Verify Active Trip Card contents (Active state)
      expect(find.text('ON DUTY'), findsOneWidget);
      expect(find.text('CR101 • CENTRAL → TUMAKURU'), findsOneWidget);
      expect(find.text('Bus: KA06F8558'), findsOneWidget);
      expect(find.text('NEXT STOP'), findsOneWidget);
      expect(find.text('Tumakuru Bus Stand'), findsOneWidget);
      expect(find.text('ETA 06 min'), findsOneWidget);
      expect(find.text('ON TIME'), findsOneWidget);
      expect(find.text('08:42 AM'), findsOneWidget);
      expect(find.text('Trip 3 of 8'), findsOneWidget);
      expect(find.text('OPEN CURRENT TRIP'), findsOneWidget);

      // Verify Bus / Vehicle Card contents
      expect(find.text('ASSIGNED BUS'), findsOneWidget);
      expect(find.text('Depot #1 • Route CR101'), findsOneWidget);

      // Verify Today Stats Row contents (2 columns only)
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('2h 45m'), findsOneWidget);
      expect(find.text('Driving'), findsOneWidget);
      expect(find.text('3/8'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('On-time'), findsNothing);

      // Verify Active Trip Card contents (Idle / Off-Duty state)
      expect(find.text('OFF DUTY'), findsOneWidget);
      expect(find.text('No trip in progress. Start your shift to begin.'), findsOneWidget);
      expect(find.text('START SHIFT'), findsOneWidget);

      // Verify interactions
      await tester.tap(find.text('OPEN CURRENT TRIP'));
      await tester.pumpAndSettle();
      expect(openCurrentTripPressed, isTrue);

      await tester.tap(find.text('ASSIGNED BUS'));
      await tester.pumpAndSettle();
      expect(busCardPressed, isTrue);

      await tester.ensureVisible(find.text('START SHIFT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('START SHIFT'));
      await tester.pumpAndSettle();
      expect(startShiftPressed, isTrue);
    });

    testWidgets('Test Y: Dynamic Safety Check reflects real checked count (0/7 initial, not hardcoded 6/7)', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // In un-checked initial state, it MUST display 0/7 completed, NEVER 6/7
      expect(find.text('0/7 completed'), findsOneWidget);
      expect(find.text('6/7 completed'), findsNothing);
      expect(find.text('REQUIRED'), findsOneWidget);

      // Expand the checklist
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Scroll to and check Brakes item
      await tester.ensureVisible(find.text('Brakes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brakes'));
      await tester.pumpAndSettle();

      // Count immediately updates to 1/7 completed
      expect(find.text('1/7 completed'), findsOneWidget);
      expect(find.text('IN PROGRESS (1/7)'), findsOneWidget);
    });

    testWidgets('Test Z: Route Page reveals trip card conditionally based on Safety Check status', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();
      await engine.validateBusNumber('KA06F8558');
      await engine.validateRouteCode('CR101');

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Route tab (Tab 1)
      await tester.tap(find.text('Route'));
      await tester.pumpAndSettle();

      // State 1: Safety check incomplete -> Info banner displayed, Active Trip card hidden
      expect(
        find.text('Complete vehicle verification and safety check on the Dashboard to start your trip.'),
        findsOneWidget,
      );
      expect(find.text('READY TO START'), findsNothing);
      expect(find.text('CURRENT TRIP'), findsNothing);

      // State 2: Pass safety check -> Interim ready state revealed
      engine.passAllInspection();
      await tester.pumpAndSettle();

      expect(find.text('READY TO START'), findsOneWidget);
      expect(find.text('Ready to start — trip will appear here once you begin your first stop'), findsOneWidget);
      expect(find.text('START TRIP'), findsOneWidget);
      expect(find.text('CURRENT TRIP'), findsNothing);

      // State 3: Start trip -> Full Active Trip hero card revealed
      engine.startTrip();
      await tester.pumpAndSettle();

      expect(find.text('CURRENT TRIP'), findsOneWidget);
      expect(find.text('LIVE IN TRANSIT'), findsOneWidget);
      expect(find.text('VIEW LIVE COCKPIT →'), findsOneWidget);
      expect(find.text('READY TO START'), findsNothing);

      // Clean up timer
      engine.endTripEarly();
      await tester.pump();
    });

    testWidgets('Test AA: Modern UI refresh renders Trip action card, Driver summary grid, and navigates on tap', (WidgetTester tester) async {
      final engine = TripEngine();
      engine.startNewTripFlow();

      await tester.pumpWidget(
        const MaterialApp(
          home: DriverDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Assigned Bus Card with KA06F8558
      expect(find.text('ASSIGNED BUS'), findsOneWidget);
      expect(find.text('KA06F8558'), findsOneWidget);

      // 2. Verify Safety Check Module
      expect(find.text('SAFETY CHECK'), findsOneWidget);

      // 3. Verify Trip Action Card directly below Safety Check
      expect(find.byType(TripActionCard), findsOneWidget);
      expect(find.text('VIEW ROUTE & TRIPS'), findsOneWidget);
      expect(find.text('Assigned stops, route map & daily schedule'), findsOneWidget);

      // 4. Verify Driver Summary Grid above Quick Actions
      expect(find.byType(DriverSummaryGrid), findsOneWidget);
      expect(find.text('Ramesh Gowda'), findsOneWidget);
      expect(find.text('ID: TUM-DRV-1042'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Driving'), findsOneWidget);
      expect(find.text('On-time'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);

      // 5. Tapping VIEW ROUTE & TRIPS navigates to Route tab (Tab 1)
      await tester.tap(find.text('VIEW ROUTE & TRIPS'));
      await tester.pumpAndSettle();

      expect(find.text('YOUR ROUTE'), findsOneWidget);
      expect(find.text('Quick Select Tumakuru Route:'), findsOneWidget);

      // Back navigation returns to Dashboard
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('ASSIGNED BUS'), findsOneWidget);
      expect(find.text('VIEW ROUTE & TRIPS'), findsOneWidget);
    });
  });
}
