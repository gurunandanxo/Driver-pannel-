import '../core/constants/transit_catalog.dart';
import '../core/utils/geo_utils.dart';
import '../core/utils/validators.dart';
import '../models/trip_models.dart';

class RouteEngineService {
  static final RouteEngineService _instance = RouteEngineService._internal();
  factory RouteEngineService() => _instance;

  RouteEngineService._internal();

  Future<TransitRoute?> verifyAndFetchRoute(String routeCodeInput) async {
    final normalized = Validators.normalizeRouteCode(routeCodeInput);
    if (!Validators.isValidRouteCode(normalized)) {
      return null;
    }

    try {
      final match = TransitCatalog.sampleRoutes.firstWhere(
        (r) => r.routeCode.toUpperCase() == normalized,
      );
      return match;
    } catch (_) {
      return null;
    }
  }

  bool isInsideStopGeofence(double currentLat, double currentLon, TransitStop stop) {
    return GeoUtils.isInsideGeofence(
      currentLat,
      currentLon,
      stop.latitude,
      stop.longitude,
      stop.geofenceRadiusMeters,
    );
  }

  double calculateRouteProgress(int currentStopIndex, int totalStops) {
    if (totalStops <= 1) return 1.0;
    return (currentStopIndex / (totalStops - 1)).clamp(0.0, 1.0);
  }
}
