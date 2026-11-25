import 'dart:math' as math;

class GeoUtils {
  static const double earthRadiusKm = 6371.0;

  /// Calculate distance between two coordinates in meters
  static double distanceBetweenMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return distanceBetweenKm(lat1, lon1, lat2, lon2) * 1000.0;
  }

  /// Calculate distance between two coordinates in kilometers using Haversine formula
  static double distanceBetweenKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(rLat1) * math.cos(rLat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculate initial bearing (compass heading 0-360) from coord1 to coord2
  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final rLat1 = _degreesToRadians(lat1);
    final rLat2 = _degreesToRadians(lat2);
    final dLon = _degreesToRadians(lon2 - lon1);

    final y = math.sin(dLon) * math.cos(rLat2);
    final x = math.cos(rLat1) * math.sin(rLat2) -
        math.sin(rLat1) * math.cos(rLat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    final degrees = (radians * 180.0 / math.pi + 360.0) % 360.0;

    return degrees;
  }

  /// Linear interpolation between two coordinates
  static (double lat, double lon) interpolate(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double fraction,
  ) {
    final clampedFraction = fraction.clamp(0.0, 1.0);
    final lat = lat1 + (lat2 - lat1) * clampedFraction;
    final lon = lon1 + (lon2 - lon1) * clampedFraction;
    return (lat, lon);
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Formats distance human-readably (e.g. "450 m" or "2.4 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Formats ETA seconds human-readably (e.g. "2 min", "45 sec", "12 min")
  static String formatEta(int seconds) {
    if (seconds <= 0) return 'Arriving now';
    if (seconds < 60) return '$seconds sec';
    final mins = (seconds / 60).ceil();
    return '$mins min';
  }

  /// Checks if coordinate is inside geofence radius
  static bool isInsideGeofence(double lat, double lon, double targetLat, double targetLon, double radiusMeters) {
    final dist = distanceBetweenMeters(lat, lon, targetLat, targetLon);
    return dist <= radiusMeters;
  }

  /// Calculates minimum distance in meters from current coordinate to a polyline route of points
  static double calculateRouteDeviationMeters(double lat, double lon, List<dynamic> points) {
    if (points.isEmpty) return 0.0;
    double minDistance = double.infinity;
    for (final pt in points) {
      final double pLat = pt.latitude as double;
      final double pLon = pt.longitude as double;
      final d = distanceBetweenMeters(lat, lon, pLat, pLon);
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  /// Formats delay minutes
  static String formatDelayMinutes(int minutes) {
    if (minutes == 0) {
      return 'ON TIME';
    } else if (minutes > 0) {
      return '+$minutes MIN DELAY';
    } else {
      return '${minutes.abs()} MIN EARLY';
    }
  }
}
