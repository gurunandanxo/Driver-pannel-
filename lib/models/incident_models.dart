class DriverIncident {
  final String id;
  final String incidentCode; // e.g. 'INC-1042'
  final String? driverId;
  final String? tripId;
  final String? vehicleId;
  final String? routeId;
  final String incidentType;
  final String description;
  final String? localPhotoPath;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String status; // 'REPORTED', 'INVESTIGATING', 'RESOLVED'
  final DateTime reportedAt;

  const DriverIncident({
    required this.id,
    required this.incidentCode,
    this.driverId,
    this.tripId,
    this.vehicleId,
    this.routeId,
    required this.incidentType,
    required this.description,
    this.localPhotoPath,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.status = 'REPORTED',
    required this.reportedAt,
  });

  static const List<String> incidentTypes = [
    'Road Obstruction',
    'Traffic Block',
    'Accident',
    'Bus Breakdown',
    'Mechanical Problem',
    'Tyre Problem',
    'Medical Emergency',
    'Road Closure',
    'Route Problem',
    'Other',
  ];

  factory DriverIncident.fromJson(Map<String, dynamic> json) {
    return DriverIncident(
      id: json['id']?.toString() ?? '',
      incidentCode: json['incident_code']?.toString() ?? json['incidentCode']?.toString() ?? 'INC-000',
      driverId: json['driver_id']?.toString(),
      tripId: json['trip_id']?.toString(),
      vehicleId: json['vehicle_id']?.toString(),
      routeId: json['route_id']?.toString(),
      incidentType: json['incident_type']?.toString() ?? 'Other',
      description: json['description']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'REPORTED',
      reportedAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'incident_code': incidentCode,
        'driver_id': driverId,
        'trip_id': tripId,
        'vehicle_id': vehicleId,
        'route_id': routeId,
        'incident_type': incidentType,
        'description': description,
        'photo_url': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
        'created_at': reportedAt.toIso8601String(),
      };
}
