import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/constants/transit_catalog.dart';
import '../core/utils/geo_utils.dart';
import '../core/utils/validators.dart';
import '../models/driver_models.dart';
import '../models/inspection_models.dart';
import '../models/trip_models.dart';
import '../models/vehicle_model.dart';
import 'driver_auth_service.dart';
import 'gps_service.dart';
import 'notification_service.dart';
import 'route_engine_service.dart';
import 'trip_history_service.dart';

class TripEngine extends ChangeNotifier {
  static final TripEngine _instance = TripEngine._internal();
  factory TripEngine() => _instance;

  TripEngine._internal() {
    _inspection = PreTripInspection.empty();
    _initEngine();
  }

  // Multi-tenant / Driver Scoped State
  String? _currentDriverId;

  // Workflow State
  DriverWorkflowState _workflowState = DriverWorkflowState.busRequired;

  // Step 1: Bus Validation
  String _enteredBusNumber = '';
  BusVehicle? _verifiedBus;
  bool _isBusValidating = false;
  String? _busError;

  // Step 2: Pre-Trip Safety Inspection
  PreTripInspection _inspection = PreTripInspection.empty();

  // Step 3: Route Verification
  String _enteredRouteCode = '';
  TransitRoute? _verifiedRoute;
  bool _isRouteValidating = false;
  String? _routeError;

  // Step 4 & 5: Active Trip State
  DriverTrip? _activeTrip;
  final bool _isActiveTripRecovered = false;
  int _currentStopIndex = 0;
  TripLegDirection _legDirection = TripLegDirection.outbound;
  int _delayMinutes = 0;
  int _etaToNextStopSeconds = 180;
  double _distanceToNextStopMeters = 0.0;
  bool _isRouteDeviated = false;
  int _incidentsCount = 0;
  DateTime? _tripStartTime;
  Timer? _tripTelemetryLoopTimer;

  // Completion lock to prevent duplicate completion events from GPS or Timer
  bool _isCompletingTrip = false;

  // Step 6: Trip Summary
  TripSummary? _lastCompletedSummary;
  final List<TripSummary> _completedTripsToday = [];

  // Driver Scoped Storage (In-memory cache per driver to prevent data bleed)
  static final Map<String, DriverTrip?> _driverActiveTrips = {};
  static final Map<String, List<TripSummary>> _driverCompletedTrips = {};
  static final Map<String, BusVehicle?> _driverBuses = {};
  static final Map<String, TransitRoute?> _driverRoutes = {};

  // Getters
  DriverWorkflowState get workflowState => _workflowState;
  String? get currentDriverId => _currentDriverId;

  String get enteredBusNumber => _enteredBusNumber;
  BusVehicle? get verifiedBus => _verifiedBus;
  bool get isBusValidating => _isBusValidating;
  String? get busError => _busError;
  bool get isBusVerified => _verifiedBus != null;

  PreTripInspection get inspection => _inspection;
  bool get isInspectionReviewed => _inspection.isReviewed;
  bool get isInspectionPassed => _inspection.isAllPassed;

  String get enteredRouteCode => _enteredRouteCode;
  TransitRoute? get verifiedRoute => _verifiedRoute;
  bool get isRouteValidating => _isRouteValidating;
  String? get routeError => _routeError;
  bool get isRouteVerified => _verifiedRoute != null;

  bool get isReadyToStart => isBusVerified && isInspectionPassed && isRouteVerified;

  DriverTrip? get activeTrip => _activeTrip;
  bool get isTripActive => _activeTrip != null && _activeTrip!.status == TripStatus.active;
  bool get isCompletingTrip => _isCompletingTrip;
  bool get isActiveTripRecovered => _isActiveTripRecovered;
  int get currentStopIndex => _currentStopIndex;
  TripLegDirection get legDirection => _legDirection;
  bool get isReturning => _legDirection == TripLegDirection.returning;
  int get delayMinutes => _delayMinutes;
  int get etaToNextStopSeconds => _etaToNextStopSeconds;
  double get distanceToNextStopMeters => _distanceToNextStopMeters;
  bool get isRouteDeviated => _isRouteDeviated;
  int get incidentsCount => _incidentsCount;

  TripSummary? get lastCompletedSummary => _lastCompletedSummary;
  List<TripSummary> get completedTripsToday => List.unmodifiable(_completedTripsToday);

  TransitStop? get currentStop {
    if (_activeTrip != null && _activeTrip!.route.stops.isNotEmpty) {
      final idx = _currentStopIndex.clamp(0, _activeTrip!.route.stops.length - 1);
      return _activeTrip!.route.stops[idx];
    }
    if (_verifiedRoute != null && _verifiedRoute!.stops.isNotEmpty) {
      final idx = _currentStopIndex.clamp(0, _verifiedRoute!.stops.length - 1);
      return _verifiedRoute!.stops[idx];
    }
    return null;
  }

  TransitStop? get nextStop {
    final stops = _activeTrip?.route.stops ?? _verifiedRoute?.stops ?? [];
    if (stops.isEmpty) return null;
    final nextIdx = _currentStopIndex + 1;
    if (nextIdx < stops.length) {
      return stops[nextIdx];
    }
    return stops.last;
  }

  TransitStop? get destinationStop {
    final stops = _activeTrip?.route.stops ?? _verifiedRoute?.stops ?? [];
    if (stops.isEmpty) return null;
    return stops.last;
  }

  void _initEngine() {
    GpsService().addListener(_onGpsPositionUpdated);
  }

  // --- DRIVER SESSION LIFECYCLE (DATA ISOLATION) ---
  void onDriverAuthenticated(DriverProfile driver) {
    if (_currentDriverId == driver.id) return;

    // Purge previous driver's transient state
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    _currentDriverId = driver.id;
    _activeTrip = _driverActiveTrips[driver.id];
    _verifiedBus = _driverBuses[driver.id];
    _verifiedRoute = _driverRoutes[driver.id];
    _enteredBusNumber = _verifiedBus?.busNumber ?? 'KA06F8558';
    _enteredRouteCode = _verifiedRoute?.routeCode ?? 'CR102';
    _inspection = PreTripInspection.empty();
    _lastCompletedSummary = null;
    _completedTripsToday.clear();
    if (_driverCompletedTrips[driver.id] != null) {
      _completedTripsToday.addAll(_driverCompletedTrips[driver.id]!);
    }

    if (_activeTrip != null && _activeTrip!.status == TripStatus.active) {
      _workflowState = DriverWorkflowState.tripActive;
      _currentStopIndex = _activeTrip!.currentStopIndex;
      _legDirection = _activeTrip!.legDirection;
      _startTelemetryBroadcastLoop();
      GpsService().startTracking(routeStops: _activeTrip!.route.stops);
    } else {
      _workflowState = _verifiedBus != null
          ? (_inspection.isAllPassed
              ? (_verifiedRoute != null
                  ? DriverWorkflowState.routeVerified
                  : DriverWorkflowState.inspectionCompleted)
              : DriverWorkflowState.busVerified)
          : DriverWorkflowState.busRequired;
    }

    debugPrint('[TripEngine] Switched to Driver: ${driver.id} (${driver.name}). Active trip: ${_activeTrip?.id ?? "None"}');
    notifyListeners();
  }

  void clearDriverSession() {
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    if (_currentDriverId != null) {
      _driverActiveTrips[_currentDriverId!] = _activeTrip;
      _driverBuses[_currentDriverId!] = _verifiedBus;
      _driverRoutes[_currentDriverId!] = _verifiedRoute;
      _driverCompletedTrips[_currentDriverId!] = List.from(_completedTripsToday);
    }

    _currentDriverId = null;
    _activeTrip = null;
    _verifiedBus = null;
    _verifiedRoute = null;
    _enteredBusNumber = '';
    _enteredRouteCode = '';
    _inspection = PreTripInspection.empty();
    _lastCompletedSummary = null;
    _completedTripsToday.clear();
    _currentStopIndex = 0;
    _legDirection = TripLegDirection.outbound;
    _isCompletingTrip = false;
    _workflowState = DriverWorkflowState.busRequired;

    debugPrint('[TripEngine] Cleared driver session and stopped tracking.');
    notifyListeners();
  }

  // --- STEP 1: BUS NUMBER VALIDATION ---
  Future<bool> validateBusNumber(String busNumberInput) async {
    _isBusValidating = true;
    _busError = null;
    notifyListeners();

    final normalized = Validators.normalizeBusNumber(busNumberInput);
    _enteredBusNumber = normalized;

    if (!Validators.isValidBusNumber(normalized)) {
      _verifiedBus = null;
      _isBusValidating = false;
      _busError = 'Please enter a valid bus number (e.g. KA06F8558)';
      notifyListeners();
      return false;
    }

    final catalogMatch = TransitCatalog.sampleBuses.firstWhere(
      (v) => v.busNumber.replaceAll(' ', '') == normalized,
      orElse: () => BusVehicle(
        id: 'BUS_${DateTime.now().millisecondsSinceEpoch}',
        busNumber: normalized,
        model: 'Tata Starbus Ultra EV',
        depotName: 'Tumakuru Central City Depot #1 (Ashoka Road)',
        capacity: 42,
        status: 'ACTIVE',
      ),
    );

    _verifiedBus = catalogMatch;
    if (_currentDriverId != null) _driverBuses[_currentDriverId!] = _verifiedBus;
    _workflowState = DriverWorkflowState.busVerified;
    _isBusValidating = false;
    _busError = null;
    notifyListeners();
    return true;
  }

  // --- STEP 2: PRE-TRIP SAFETY INSPECTION ---
  void setInspectionCheck({
    bool? fuel,
    bool? air,
    bool? brakes,
    bool? tyres,
    bool? lights,
    bool? doors,
    bool? horn,
    bool? mirrors,
    bool? firstAid,
    bool? otherIssuePresent,
    String? otherIssueDescription,
    String? otherIssueLocalPhotoPath,
  }) {
    _inspection = _inspection.copyWith(
      fuelOk: fuel,
      airOk: air,
      brakesOk: brakes,
      tyresOk: tyres,
      lightsOk: lights,
      doorsOk: doors,
      hornOk: horn,
      mirrorsOk: mirrors,
      firstAidOk: firstAid,
      otherIssuePresent: otherIssuePresent ?? false,
      otherIssueDescription: otherIssueDescription,
      otherIssueLocalPhotoPath: otherIssueLocalPhotoPath,
    );

    if (_inspection.isAllPassed) {
      _workflowState = DriverWorkflowState.inspectionCompleted;
    }
    notifyListeners();
  }

  void toggleInspectionItem(String key, bool passed) {
    _inspection = _inspection.toggleCheck(key, passed);
    if (_inspection.isFullyCompleted) {
      _workflowState = DriverWorkflowState.inspectionCompleted;
    } else if (_workflowState == DriverWorkflowState.inspectionCompleted && !_inspection.isFullyCompleted) {
      _workflowState = _verifiedBus != null ? DriverWorkflowState.busVerified : DriverWorkflowState.busRequired;
    }
    notifyListeners();
  }

  void passAllInspection() {
    _inspection = PreTripInspection.allPassed();
    _workflowState = DriverWorkflowState.inspectionCompleted;
    notifyListeners();
  }

  void updateInspection(PreTripInspection inspection) {
    _inspection = inspection;
    if (inspection.isAllPassed) {
      _workflowState = DriverWorkflowState.inspectionCompleted;
    }
    notifyListeners();
  }

  Future<void> submitInspectionReport() async {
    _workflowState = DriverWorkflowState.inspectionCompleted;
    notifyListeners();
  }

  Future<void> submitInspectionWithIssue({
    String? problemType,
    String? issueType,
    required String description,
    String? localPhotoPath,
    String? photoPath,
  }) async {
    final type = problemType ?? issueType ?? 'Safety Issue';
    final photo = localPhotoPath ?? photoPath;
    _inspection = _inspection.copyWith(
      otherIssuePresent: true,
      otherIssueDescription: '$type: $description',
      otherIssueLocalPhotoPath: photo,
    );
    await submitInspectionReport();
  }

  int _routeValidationToken = 0;

  // --- STEP 3: ROUTE CODE VERIFICATION ---
  Future<bool> validateRouteCode(String routeCodeInput) async {
    final currentToken = ++_routeValidationToken;
    _isRouteValidating = true;
    _routeError = null;
    notifyListeners();

    final normalized = Validators.normalizeRouteCode(routeCodeInput);
    _enteredRouteCode = normalized;

    // Reset previous active trip state, completion state, and stop index completely!
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    _activeTrip = null;
    _lastCompletedSummary = null;
    _isCompletingTrip = false;
    _currentStopIndex = 0;
    _legDirection = TripLegDirection.outbound;
    _delayMinutes = 0;
    _distanceToNextStopMeters = 0.0;
    _etaToNextStopSeconds = 180;
    _isRouteDeviated = false;

    if (_currentDriverId != null) {
      _driverActiveTrips[_currentDriverId!] = null;
    }

    if (!Validators.isValidRouteCode(normalized)) {
      if (currentToken != _routeValidationToken) return false;
      _verifiedRoute = null;
      _isRouteValidating = false;
      _routeError = 'Please enter a valid route code (e.g. CR101, CR102)';
      notifyListeners();
      return false;
    }

    if (currentToken != _routeValidationToken) return false;

    final catalogMatch = TransitCatalog.sampleRoutes.firstWhere(
      (r) => r.routeCode.toUpperCase() == normalized,
      orElse: () => TransitRoute(
        id: 'ROUTE_$normalized',
        routeCode: normalized,
        routeName: '$normalized Transit Loop',
        origin: 'KSRTC Bus Stand',
        destination: 'KSRTC Bus Stand',
        totalDistanceKm: 7.6,
        estimatedDurationMinutes: 24,
        stops: TransitCatalog.cr102Stops,
      ),
    );

    _verifiedRoute = catalogMatch;
    if (_currentDriverId != null) _driverRoutes[_currentDriverId!] = _verifiedRoute;
    _workflowState = DriverWorkflowState.routeVerified;
    _isRouteValidating = false;
    _routeError = null;
    notifyListeners();
    return true;
  }

  // --- MANUAL STOP ADVANCE (FALLBACK / MANUAL OVERRIDE) ---
  void manualAdvanceToNextStop() {
    if (!isTripActive || _isCompletingTrip || _activeTrip == null) return;
    final stops = _activeTrip!.route.stops;
    if (stops.isEmpty) return;

    final nextTargetIndex = _currentStopIndex + 1;
    if (nextTargetIndex < stops.length) {
      _currentStopIndex = nextTargetIndex;
      final midpoint = (stops.length / 2).floor();
      if (_currentStopIndex >= midpoint || stops[nextTargetIndex].isReturnStop) {
        _legDirection = TripLegDirection.returning;
      }

      final reachedStop = stops[nextTargetIndex];
      debugPrint('[TripEngine] MANUAL_STOP_ADVANCE: ${reachedStop.name} (Stop ${_currentStopIndex + 1}/${stops.length})');

      NotificationService().addNotification(
        title: 'Stop Reached',
        message: 'Arrived at ${reachedStop.name}',
        type: 'TRIP',
      );

      if (_currentStopIndex == stops.length - 1) {
        debugPrint('[TripEngine] DESTINATION_REACHED: ${reachedStop.name} (Final Return Stop)');
        _completeTripAutomatically();
      } else {
        notifyListeners();
      }
    }
  }

  // --- MANUAL END / CANCEL TRIP (EARLY TERMINATION) ---
  void endTripEarly({String reason = 'Driver ended trip early'}) {
    if (_activeTrip == null) return;

    final tripSnapshot = _activeTrip!;

    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    NotificationService().addNotification(
      title: 'Trip Ended Early',
      message: 'Trip on route ${tripSnapshot.route.routeCode} was stopped.',
      type: 'TRIP',
    );

    _activeTrip = null;
    if (_currentDriverId != null) {
      _driverActiveTrips[_currentDriverId!] = null;
      _driverRoutes[_currentDriverId!] = null;
    }

    _enteredRouteCode = '';
    _verifiedRoute = null;
    _currentStopIndex = 0;
    _legDirection = TripLegDirection.outbound;
    _delayMinutes = 0;
    _distanceToNextStopMeters = 0.0;
    _etaToNextStopSeconds = 180;
    _isCompletingTrip = false;
    _lastCompletedSummary = null;

    _workflowState = DriverWorkflowState.busVerified;
    notifyListeners();
  }

  // --- STEP 4: START ACTIVE TRIP ---
  bool startTrip() {
    if (!isReadyToStart) return false;

    final driver = DriverAuthService().activeDriver;
    final driverId = driver?.id ?? _currentDriverId ?? 'DRV_001';
    final now = DateTime.now();

    final newTrip = DriverTrip(
      id: 'TRIP_${_verifiedRoute!.routeCode}_${now.millisecondsSinceEpoch}',
      driverId: driverId,
      bus: _verifiedBus!,
      route: _verifiedRoute!,
      status: TripStatus.active,
      legDirection: TripLegDirection.outbound,
      startedAt: now,
      currentStopIndex: 0,
      stopsCompleted: 0,
    );

    _activeTrip = newTrip;
    _driverActiveTrips[driverId] = newTrip;
    _tripStartTime = now;
    _currentStopIndex = 0;
    _legDirection = TripLegDirection.outbound;
    _delayMinutes = 0;
    _incidentsCount = 0;
    _isRouteDeviated = false;
    _isCompletingTrip = false;
    _workflowState = DriverWorkflowState.tripActive;

    debugPrint('[TripEngine] TRIP_START: ${newTrip.id} by Driver $driverId on Bus: ${newTrip.bus.busNumber} Route: ${newTrip.route.routeCode} (${newTrip.route.stops.length} stops)');

    // Start GPS Engine & Telemetry Broadcast Loop
    GpsService().startTracking(routeStops: _verifiedRoute!.stops);
    _startTelemetryBroadcastLoop();

    NotificationService().addNotification(
      title: 'Trip Started',
      message: 'Started Route ${_verifiedRoute!.routeCode} on vehicle ${_verifiedBus!.busNumber}.',
      type: 'TRIP',
    );

    notifyListeners();
    return true;
  }

  // --- STEP 5: ACTIVE TRIP GPS & MULTI-STOP GEOFENCING ---
  void _startTelemetryBroadcastLoop() {
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = Timer.periodic(AppConfig.telemetryBroadcastInterval, (_) {
      _processTripTelemetryTick();
    });
  }

  void _onGpsPositionUpdated() {
    if (_activeTrip == null || _activeTrip!.status != TripStatus.active || _isCompletingTrip) return;
    _checkStopGeofencing();
  }

  void _processTripTelemetryTick() {
    if (_activeTrip == null || _activeTrip!.status != TripStatus.active || _isCompletingTrip) return;

    final gps = GpsService();
    final stops = _activeTrip!.route.stops;
    if (stops.isEmpty) return;

    // 1. Check Route Deviation
    final devDist = GeoUtils.calculateRouteDeviationMeters(gps.latitude, gps.longitude, stops);
    _isRouteDeviated = devDist > AppConfig.routeDeviationThresholdMeters;

    // 2. Compute Distance & Dynamic ETA
    final targetStop = nextStop ?? stops.last;
    final distToTarget = GeoUtils.distanceBetweenMeters(
      gps.latitude,
      gps.longitude,
      targetStop.latitude,
      targetStop.longitude,
    );
    _distanceToNextStopMeters = distToTarget;

    final speed = gps.speedKmh > 5.0 ? gps.speedKmh : 24.0;
    _etaToNextStopSeconds = (distToTarget / (speed * 1000 / 3600)).round();

    // 3. Dynamic Delay Calculation
    if (_tripStartTime != null) {
      final elapsedMinutes = DateTime.now().difference(_tripStartTime!).inMinutes;
      final expectedMinutes = (_currentStopIndex + 1) * 4;
      _delayMinutes = (elapsedMinutes - expectedMinutes).clamp(0, 60);
    }

    // 4. Update Direction (Outbound vs Returning)
    final midpoint = (stops.length / 2).floor();
    if (_currentStopIndex >= midpoint || (currentStop?.isReturnStop ?? false)) {
      _legDirection = TripLegDirection.returning;
    } else {
      _legDirection = TripLegDirection.outbound;
    }

    // 5. Check Geofences
    _checkStopGeofencing();

    notifyListeners();
  }

  void _checkStopGeofencing() {
    if (_activeTrip == null || _activeTrip!.status != TripStatus.active || _isCompletingTrip) return;

    final gps = GpsService();
    final stops = _activeTrip!.route.stops;
    if (stops.isEmpty) return;

    // Sequential single-step check for accurate ordered transit progression
    final nextTargetIndex = _currentStopIndex + 1;
    if (nextTargetIndex < stops.length) {
      final nextStopCandidate = stops[nextTargetIndex];
      final isInside = RouteEngineService().isInsideStopGeofence(
        gps.latitude,
        gps.longitude,
        nextStopCandidate,
      );

      if (isInside) {
        _currentStopIndex = nextTargetIndex;
        final midpoint = (stops.length / 2).floor();
        if (_currentStopIndex >= midpoint || nextStopCandidate.isReturnStop) {
          _legDirection = TripLegDirection.returning;
        }

        debugPrint('[TripEngine] STOP_REACHED: ${nextStopCandidate.name} (Stop ${_currentStopIndex + 1}/${stops.length}) - Leg: ${_legDirection.displayName}');

        NotificationService().addNotification(
          title: 'Stop Reached',
          message: 'Arrived at ${nextStopCandidate.name}',
          type: 'TRIP',
        );

        // ONLY complete the trip if reaching the FINAL return destination!
        if (_currentStopIndex == stops.length - 1) {
          debugPrint('[TripEngine] DESTINATION_REACHED: ${nextStopCandidate.name} (Final Return Stop)');
          _completeTripAutomatically();
        }
      }
    }
  }

  // --- STEP 6: DESTINATION COMPLETION (SAFE & DRIVER-SCOPED) ---
  void _completeTripAutomatically() {
    if (_isCompletingTrip || _activeTrip == null) return;
    _isCompletingTrip = true;

    final tripSnapshot = _activeTrip!;
    final tripId = tripSnapshot.id;
    final driverId = tripSnapshot.driverId;
    debugPrint('[TripEngine] TRIP_COMPLETION_STARTED: $tripId for Driver: $driverId');

    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    final endTime = DateTime.now();
    final startTime = _tripStartTime ?? tripSnapshot.startedAt;
    final duration = endTime.difference(startTime);

    final summary = TripSummary(
      tripId: tripId,
      driverId: driverId,
      routeCode: tripSnapshot.route.routeCode,
      routeName: tripSnapshot.route.routeName,
      busNumber: tripSnapshot.bus.busNumber,
      origin: tripSnapshot.route.origin,
      destination: tripSnapshot.route.destination,
      startLocation: tripSnapshot.route.startLocation,
      outboundDestination: tripSnapshot.route.outboundDestination,
      returnLocation: tripSnapshot.route.returnLocation,
      stops: List.from(tripSnapshot.route.stops),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      delayMinutes: _delayMinutes,
      stopsCompleted: tripSnapshot.route.stops.length,
      totalStops: tripSnapshot.route.stops.length,
      incidentsCount: _incidentsCount,
    );

    _lastCompletedSummary = summary;
    _completedTripsToday.insert(0, summary);
    _driverCompletedTrips[driverId] = List.from(_completedTripsToday);

    // Save to permanent history service & Database sync
    debugPrint('[TripEngine] TRIP_DATABASE_SAVE_STARTED: $tripId');
    TripHistoryService().addCompletedRecord(summary);
    debugPrint('[TripEngine] TRIP_DATABASE_SAVE_SUCCESS: $tripId');

    NotificationService().addNotification(
      title: 'Trip Completed ✓',
      message: 'Round-trip ${summary.routeCode} completed successfully in ${summary.duration.inMinutes} mins.',
      type: 'TRIP',
    );

    // Mark trip completed and clear driver active trip
    _activeTrip = tripSnapshot.copyWith(status: TripStatus.completed, completedAt: endTime);
    _driverActiveTrips[driverId] = null;
    _workflowState = DriverWorkflowState.destinationReached;
    _isCompletingTrip = false;

    debugPrint('[TripEngine] ACTIVE_TRIP_CLEARED: $tripId');
    debugPrint('[TripEngine] HISTORY_UPDATED: $tripId');

    notifyListeners();
  }

  // Called when driver taps "BACK TO DASHBOARD" from Trip Summary
  void finishTripAndReturnToDashboard() {
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    _activeTrip = null;
    _lastCompletedSummary = null;
    _isCompletingTrip = false;
    _currentStopIndex = 0;
    _legDirection = TripLegDirection.outbound;
    _delayMinutes = 0;
    _distanceToNextStopMeters = 0.0;
    _etaToNextStopSeconds = 180;
    _isRouteDeviated = false;

    if (_currentDriverId != null) {
      _driverActiveTrips[_currentDriverId!] = null;
      _driverRoutes[_currentDriverId!] = null;
    }
    _enteredRouteCode = '';
    _verifiedRoute = null;
    _workflowState = DriverWorkflowState.busVerified; // Keeps vehicle, ready for next route
    notifyListeners();
  }

  // Reset only Route verification (Step 3) - preserves verified bus and passed inspection
  void resetRoute() {
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    _activeTrip = null;
    _lastCompletedSummary = null;
    _isCompletingTrip = false;
    _currentStopIndex = 0;
    _legDirection = TripLegDirection.outbound;
    _delayMinutes = 0;
    _distanceToNextStopMeters = 0.0;
    _etaToNextStopSeconds = 180;
    _isRouteDeviated = false;

    _enteredRouteCode = '';
    _verifiedRoute = null;
    _routeError = null;
    _isRouteValidating = false;
    if (_currentDriverId != null) {
      _driverActiveTrips[_currentDriverId!] = null;
      _driverRoutes[_currentDriverId!] = null;
    }
    _workflowState = isInspectionPassed
        ? DriverWorkflowState.inspectionCompleted
        : (isBusVerified
            ? DriverWorkflowState.busVerified
            : DriverWorkflowState.busRequired);
    notifyListeners();
  }

  void cancelActiveTripAndResetRoute() {
    resetRoute();
  }

  // Reset Bus & Safety Check (Step 1 & Step 2)
  void resetBus() {
    _enteredBusNumber = '';
    _verifiedBus = null;
    _busError = null;
    _isBusValidating = false;
    _inspection = PreTripInspection.empty();
    _enteredRouteCode = '';
    _verifiedRoute = null;
    _routeError = null;
    _isRouteValidating = false;
    if (_currentDriverId != null) {
      _driverBuses[_currentDriverId!] = null;
      _driverRoutes[_currentDriverId!] = null;
    }
    _workflowState = DriverWorkflowState.busRequired;
    notifyListeners();
  }

  // --- STEP 7: START NEW TRIP (RESETS STATE FOR NEXT TRIP) ---
  void startNewTripFlow() {
    _tripTelemetryLoopTimer?.cancel();
    _tripTelemetryLoopTimer = null;
    GpsService().stopTracking();

    _enteredBusNumber = '';
    _verifiedBus = null;
    _busError = null;
    _inspection = PreTripInspection.empty();
    _enteredRouteCode = '';
    _verifiedRoute = null;
    _routeError = null;
    _activeTrip = null;
    _lastCompletedSummary = null;
    _isCompletingTrip = false;
    if (_currentDriverId != null) {
      _driverActiveTrips[_currentDriverId!] = null;
      _driverBuses[_currentDriverId!] = null;
      _driverRoutes[_currentDriverId!] = null;
    }
    _workflowState = DriverWorkflowState.busRequired;
    notifyListeners();
  }

  void incrementIncidentCount() {
    _incidentsCount++;
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    final driver = DriverAuthService().activeDriver;
    if (driver == null) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _tripTelemetryLoopTimer?.cancel();
    GpsService().removeListener(_onGpsPositionUpdated);
    super.dispose();
  }
}
