class VehicleTelemetryPacket {
  final String tripId;
  final String driverId;
  final String vehicleId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double headingDegrees;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isLive;

  const VehicleTelemetryPacket({
    required this.tripId,
    required this.driverId,
    required this.vehicleId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0.0,
    this.headingDegrees = 0.0,
    this.accuracyMeters = 5.0,
    required this.timestamp,
    this.isLive = true,
  });

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'driver_id': driverId,
        'vehicle_id': vehicleId,
        'route_id': routeId,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speedKmh,
        'heading': headingDegrees,
        'accuracy': accuracyMeters,
        'recorded_at': timestamp.toIso8601String(),
      };
}
