enum SosStatus {
  triggered,
  acknowledged,
  responding,
  resolved,
}

extension SosStatusExtension on SosStatus {
  String get displayName {
    switch (this) {
      case SosStatus.triggered:
        return 'TRIGGERED';
      case SosStatus.acknowledged:
        return 'ACKNOWLEDGED';
      case SosStatus.responding:
        return 'RESPONDING';
      case SosStatus.resolved:
        return 'RESOLVED';
    }
  }

  String get description {
    switch (this) {
      case SosStatus.triggered:
        return 'Emergency alert sent to Control Room. Awaiting dispatcher pickup.';
      case SosStatus.acknowledged:
        return 'OCC Dispatcher has acknowledged alert. Contacting emergency services.';
      case SosStatus.responding:
        return 'Emergency response units (Police/Ambulance/Depot) notified with live GPS coordinates.';
      case SosStatus.resolved:
        return 'Emergency situation marked as resolved by Operations Controller.';
    }
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String type; // 'POLICE', 'AMBULANCE', 'DEPOT', 'ADMIN', 'EMERGENCY'
  final String phone;
  final int priority;
  final bool active;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    this.priority = 1,
    this.active = true,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'EMERGENCY',
      phone: json['phone']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      active: json['active'] as bool? ?? true,
    );
  }

  static const List<EmergencyContact> defaultContacts = [
    EmergencyContact(
      id: 'EMERG_01',
      name: 'Police Control Room',
      type: 'POLICE',
      phone: '112',
      priority: 1,
    ),
    EmergencyContact(
      id: 'EMERG_02',
      name: 'Emergency Medical (Ambulance)',
      type: 'AMBULANCE',
      phone: '108',
      priority: 2,
    ),
    EmergencyContact(
      id: 'EMERG_03',
      name: 'Depot Control (Tumakuru)',
      type: 'DEPOT',
      phone: '08162278000',
      priority: 3,
    ),
    EmergencyContact(
      id: 'EMERG_04',
      name: 'CityRide Admin Helpdesk',
      type: 'ADMIN',
      phone: '18004257890',
      priority: 4,
    ),
    EmergencyContact(
      id: 'EMERG_05',
      name: 'Duty Officer Hotline',
      type: 'EMERGENCY',
      phone: '9448087654',
      priority: 5,
    ),
  ];
}

class EmergencySosAlert {
  final String id;
  final String tripId;
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehicleReg;
  final String routeId;
  final String routeName;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final DateTime triggeredAt;
  final SosStatus status;
  final String? acknowledgedByDispatcher;
  final DateTime? acknowledgedAt;
  final String? resolutionNotes;

  const EmergencySosAlert({
    required this.id,
    required this.tripId,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehicleReg,
    required this.routeId,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.triggeredAt,
    this.status = SosStatus.triggered,
    this.acknowledgedByDispatcher,
    this.acknowledgedAt,
    this.resolutionNotes,
  });

  EmergencySosAlert copyWith({
    SosStatus? status,
    String? acknowledgedByDispatcher,
    DateTime? acknowledgedAt,
    String? resolutionNotes,
  }) {
    return EmergencySosAlert(
      id: id,
      tripId: tripId,
      driverId: driverId,
      driverName: driverName,
      vehicleId: vehicleId,
      vehicleReg: vehicleReg,
      routeId: routeId,
      routeName: routeName,
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
      triggeredAt: triggeredAt,
      status: status ?? this.status,
      acknowledgedByDispatcher: acknowledgedByDispatcher ?? this.acknowledgedByDispatcher,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trip_id': tripId,
        'driver_id': driverId,
        'driver_name': driverName,
        'vehicle_id': vehicleId,
        'vehicle_reg': vehicleReg,
        'route_id': routeId,
        'route_name': routeName,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'triggered_at': triggeredAt.toIso8601String(),
        'status': status.name.toUpperCase(),
        'acknowledged_by': acknowledgedByDispatcher,
        'acknowledged_at': acknowledgedAt?.toIso8601String(),
      };
}
