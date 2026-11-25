import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/incident_models.dart';
import 'driver_auth_service.dart';
import 'gps_service.dart';

class IncidentService extends ChangeNotifier {
  static final IncidentService _instance = IncidentService._internal();
  factory IncidentService() => _instance;

  IncidentService._internal() {
    _loadSampleIncidents();
  }

  final List<DriverIncident> _incidents = [];
  bool _isSubmitting = false;

  List<DriverIncident> get incidents => List.unmodifiable(_incidents);
  bool get isSubmitting => _isSubmitting;

  Future<DriverIncident?> submitIncident({
    required String incidentType,
    required String description,
    String? tripId,
    String? vehicleId,
    String? routeId,
    String? localPhotoPath,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final driver = DriverAuthService().activeDriver;
    final gps = GpsService();
    final randomCode = 'INC-${1000 + math.Random().nextInt(9000)}';
    final incidentId = 'INC_${DateTime.now().millisecondsSinceEpoch}';

    final newIncident = DriverIncident(
      id: incidentId,
      incidentCode: randomCode,
      driverId: driver?.id,
      tripId: tripId,
      vehicleId: vehicleId,
      routeId: routeId,
      incidentType: incidentType,
      description: description,
      localPhotoPath: localPhotoPath,
      photoUrl: localPhotoPath,
      latitude: gps.latitude,
      longitude: gps.longitude,
      status: 'REPORTED',
      reportedAt: DateTime.now(),
    );

    _incidents.insert(0, newIncident);

    _isSubmitting = false;
    notifyListeners();
    return newIncident;
  }

  void _loadSampleIncidents() {
    _incidents.add(
      DriverIncident(
        id: 'INC_001',
        incidentCode: 'INC-1048',
        incidentType: 'Traffic Block',
        description: 'Road repair bottleneck near Town Hall Circle causing 5 min slow down.',
        latitude: 13.3325,
        longitude: 77.1080,
        status: 'INVESTIGATING',
        reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
  }
}
