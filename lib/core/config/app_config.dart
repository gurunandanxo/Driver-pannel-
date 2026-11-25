class AppConfig {
  static const String appName = 'CITYRIDE Driver Panel';
  static const String appVersion = '1.0.0';

  // Storage Buckets
  static const String profilePhotosBucket = 'driver_profiles';
  static const String incidentPhotosBucket = 'incident_photos';
  static const String inspectionPhotosBucket = 'inspection_photos';

  // Geofencing & Telemetry Parameters
  static const double defaultGeofenceRadiusMeters = 50.0;
  static const double destinationGeofenceRadiusMeters = 55.0;
  static const double routeDeviationThresholdMeters = 150.0;
  static const Duration telemetryBroadcastInterval = Duration(seconds: 2);
  static const Duration offlineBufferSyncInterval = Duration(seconds: 15);

  // GPS Status Freshness Thresholds
  static const int gpsFreshLiveThresholdSeconds = 8;
  static const int gpsFreshReconnectingThresholdSeconds = 25;
}
