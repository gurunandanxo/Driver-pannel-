import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config/app_config.dart';
import '../core/utils/geo_utils.dart';
import '../models/trip_models.dart';

enum GpsSignalStatus {
  searching,
  live,
  reconnecting,
  permissionRequired,
  disabled,
}

class GpsService extends ChangeNotifier {
  static final GpsService _instance = GpsService._internal();
  factory GpsService() => _instance;

  GpsService._internal();

  bool _isTracking = false;
  GpsSignalStatus _signalStatus = GpsSignalStatus.searching;
  double _latitude = 13.3395;
  double _longitude = 77.1005;
  double _speedKmh = 0.0;
  double _headingDegrees = 140.0;
  double _accuracyMeters = 5.0;
  DateTime _lastTimestamp = DateTime.now();

  StreamSubscription<Position>? _positionStreamSub;
  Timer? _simulationTimer;
  List<TransitStop> _activeRouteStops = [];
  int _simulationStopIndex = 0;
  double _simulationLegProgress = 0.0;

  bool get isTracking => _isTracking;
  GpsSignalStatus get signalStatus => _signalStatus;
  bool get isGpsLive => _signalStatus == GpsSignalStatus.live;
  double get latitude => _latitude;
  double get longitude => _longitude;
  double get speedKmh => _speedKmh;
  double get headingDegrees => _headingDegrees;
  double get accuracyMeters => _accuracyMeters;
  DateTime get lastTimestamp => _lastTimestamp;

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _signalStatus = GpsSignalStatus.disabled;
        notifyListeners();
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _signalStatus = GpsSignalStatus.permissionRequired;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _signalStatus = GpsSignalStatus.permissionRequired;
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[GpsService] Permission check error: $e');
      return true; // Fallback to simulated GPS
    }
  }

  void startTracking({List<TransitStop>? routeStops}) {
    _isTracking = true;
    _signalStatus = GpsSignalStatus.live;
    _activeRouteStops = routeStops ?? [];
    _simulationStopIndex = 0;
    _simulationLegProgress = 0.0;

    if (_activeRouteStops.isNotEmpty) {
      _latitude = _activeRouteStops.first.latitude;
      _longitude = _activeRouteStops.first.longitude;
    }

    _tryStartDeviceGpsStream();
    _startSimulationLoop();
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _signalStatus = GpsSignalStatus.searching;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _speedKmh = 0.0;
    notifyListeners();
  }

  void _tryStartDeviceGpsStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position pos) {
          if (_isTracking) {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
            _speedKmh = (pos.speed * 3.6).clamp(0.0, 80.0);
            _headingDegrees = pos.heading;
            _accuracyMeters = pos.accuracy;
            _lastTimestamp = DateTime.now();
            _signalStatus = GpsSignalStatus.live;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('[GpsService] Device GPS stream error: $err. Simulation active.');
        },
      );
    } catch (e) {
      debugPrint('[GpsService] Native location stream not active: $e');
    }
  }

  void _startSimulationLoop() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(AppConfig.telemetryBroadcastInterval, (_) {
      if (!_isTracking || _activeRouteStops.isEmpty) return;

      if (_simulationStopIndex < _activeRouteStops.length - 1) {
        final fromStop = _activeRouteStops[_simulationStopIndex];
        final toStop = _activeRouteStops[_simulationStopIndex + 1];

        _simulationLegProgress += 0.08; // smooth progression between stops
        if (_simulationLegProgress >= 1.0) {
          _simulationLegProgress = 0.0;
          _simulationStopIndex++;
          _latitude = toStop.latitude;
          _longitude = toStop.longitude;
          _speedKmh = 0.0;
        } else {
          final (lat, lon) = GeoUtils.interpolate(
            fromStop.latitude,
            fromStop.longitude,
            toStop.latitude,
            toStop.longitude,
            _simulationLegProgress,
          );

          _latitude = lat;
          _longitude = lon;
          _headingDegrees = GeoUtils.calculateBearing(
            fromStop.latitude,
            fromStop.longitude,
            toStop.latitude,
            toStop.longitude,
          );

          // Simulated speed variance (25 to 38 km/h)
          final baseSpeed = 28.0 + math.sin(_simulationLegProgress * math.pi) * 8.0;
          _speedKmh = (baseSpeed + (math.Random().nextDouble() * 2.0 - 1.0)).clamp(0.0, 45.0);
        }

        _lastTimestamp = DateTime.now();
        _signalStatus = GpsSignalStatus.live;
        notifyListeners();
      } else {
        // Reached destination stop
        _latitude = _activeRouteStops.last.latitude;
        _longitude = _activeRouteStops.last.longitude;
        _speedKmh = 0.0;
        _lastTimestamp = DateTime.now();
        _signalStatus = GpsSignalStatus.live;
        notifyListeners();
      }
    });
  }

  void setManualPosition(double lat, double lon, {double? heading, double? speed}) {
    _latitude = lat;
    _longitude = lon;
    if (heading != null) _headingDegrees = heading;
    if (speed != null) _speedKmh = speed;
    _lastTimestamp = DateTime.now();
    _signalStatus = GpsSignalStatus.live;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
