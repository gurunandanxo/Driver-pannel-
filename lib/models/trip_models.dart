import 'vehicle_model.dart';

enum DriverWorkflowState {
  authenticated,
  busRequired,
  busVerified,
  inspectionRequired,
  inspectionCompleted,
  routeRequired,
  routeVerified,
  readyToStart,
  tripActive,
  destinationReached,
  tripCompleted,
}

enum TripStatus {
  scheduled,
  readyForDeparture,
  active,
  completed,
  cancelled,
  endedEarly,
}

enum TripLegDirection {
  outbound,
  returning,
}

extension TripLegDirectionExtension on TripLegDirection {
  String get displayName {
    switch (this) {
      case TripLegDirection.outbound:
        return 'OUTBOUND';
      case TripLegDirection.returning:
        return 'RETURNING';
    }
  }
}

extension TripStatusExtension on TripStatus {
  String get displayName {
    switch (this) {
      case TripStatus.scheduled:
        return 'SCHEDULED';
      case TripStatus.readyForDeparture:
        return 'READY FOR DEPARTURE';
      case TripStatus.active:
        return 'IN PROGRESS';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
      case TripStatus.endedEarly:
        return 'ENDED EARLY';
    }
  }
}

class TransitStop {
  final String id;
  final String routeId;
  final int sequenceOrder;
  final String name;
  final String kannadaName;
  final String landmark;
  final double latitude;
  final double longitude;
  final double geofenceRadiusMeters;
  final int estimatedDurationMinutes;
  final bool isReturnStop;
  final bool active;

  const TransitStop({
    required this.id,
    required this.routeId,
    required this.sequenceOrder,
    required this.name,
    this.kannadaName = '',
    this.landmark = '',
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusMeters = 50.0,
    this.estimatedDurationMinutes = 4,
    this.isReturnStop = false,
    this.active = true,
  });

  factory TransitStop.fromJson(Map<String, dynamic> json) {
    return TransitStop(
      id: json['id']?.toString() ?? '',
      routeId: json['route_id']?.toString() ?? '',
      sequenceOrder: (json['sequence_order'] as num?)?.toInt() ?? (json['stop_order'] as num?)?.toInt() ?? 1,
      name: json['stop_name']?.toString() ?? json['name']?.toString() ?? '',
      kannadaName: json['local_name']?.toString() ?? json['kannada_name']?.toString() ?? '',
      landmark: json['landmark']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 13.3395,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.1005,
      geofenceRadiusMeters: (json['geofence_radius'] as num?)?.toDouble() ?? 50.0,
      estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)?.toInt() ?? 4,
      isReturnStop: json['is_return_stop'] as bool? ?? (json['stop_type'] == 'RETURN'),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route_id': routeId,
        'sequence_order': sequenceOrder,
        'stop_name': name,
        'local_name': kannadaName,
        'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius': geofenceRadiusMeters,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'is_return_stop': isReturnStop,
        'active': active,
      };
}

class TransitRoute {
  final String id;
  final String routeCode; // Format: CR101, CR102
  final String routeName;
  final String origin;
  final String destination;
  final String startLocation;
  final String outboundDestination;
  final String returnLocation;
  final String direction;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final int speedLimitKmh;
  final String colorHex;
  final List<TransitStop> stops;
  final bool isRoundTrip;
  final bool active;

  const TransitRoute({
    required this.id,
    required this.routeCode,
    required this.routeName,
    required this.origin,
    required this.destination,
    this.startLocation = 'KSRTC Bus Stand',
    this.outboundDestination = 'SIT Back Gate',
    this.returnLocation = 'KSRTC Bus Stand',
    this.direction = 'ROUND_TRIP',
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    this.speedLimitKmh = 40,
    this.colorHex = '#05684B',
    this.stops = const [],
    this.isRoundTrip = true,
    this.active = true,
  });

  String get routeSummary => '$startLocation → $outboundDestination → $returnLocation';
  String get routePathDescription => routeSummary;

  TransitStop? get originStop => stops.isNotEmpty ? stops.first : null;
  TransitStop? get finalReturnStop => stops.isNotEmpty ? stops.last : null;

  factory TransitRoute.fromJson(Map<String, dynamic> json, [List<TransitStop>? stopsList]) {
    final orig = json['origin']?.toString() ?? 'KSRTC Bus Stand';
    final dest = json['destination']?.toString() ?? 'KSRTC Bus Stand';
    final startLoc = json['start_location']?.toString() ?? json['startLocation']?.toString() ?? orig;
    final outDest = json['outbound_destination']?.toString() ?? json['outboundDestination']?.toString() ?? 'SIT Back Gate';
    final retLoc = json['return_location']?.toString() ?? json['returnLocation']?.toString() ?? dest;

    return TransitRoute(
      id: json['id']?.toString() ?? '',
      routeCode: json['route_code']?.toString() ?? json['routeCode']?.toString() ?? '',
      routeName: json['route_name']?.toString() ?? json['routeName']?.toString() ?? '',
      origin: orig,
      destination: dest,
      startLocation: startLoc,
      outboundDestination: outDest,
      returnLocation: retLoc,
      direction: json['direction']?.toString() ?? 'ROUND_TRIP',
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 6.8,
      estimatedDurationMinutes: (json['estimated_duration_minutes'] as num?)?.toInt() ?? 25,
      speedLimitKmh: (json['speed_limit_kmh'] as num?)?.toInt() ?? 40,
      colorHex: json['color_hex']?.toString() ?? '#05684B',
      stops: stopsList ?? const [],
      isRoundTrip: json['is_round_trip'] as bool? ?? true,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route_code': routeCode,
        'route_name': routeName,
        'origin': origin,
        'destination': destination,
        'start_location': startLocation,
        'outbound_destination': outboundDestination,
        'return_location': returnLocation,
        'route_summary': routeSummary,
        'direction': direction,
        'total_distance_km': totalDistanceKm,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'speed_limit_kmh': speedLimitKmh,
        'color_hex': colorHex,
        'is_round_trip': isRoundTrip,
        'active': active,
      };

  TransitRoute copyWith({
    List<TransitStop>? stops,
    String? startLocation,
    String? outboundDestination,
    String? returnLocation,
  }) {
    return TransitRoute(
      id: id,
      routeCode: routeCode,
      routeName: routeName,
      origin: origin,
      destination: destination,
      startLocation: startLocation ?? this.startLocation,
      outboundDestination: outboundDestination ?? this.outboundDestination,
      returnLocation: returnLocation ?? this.returnLocation,
      direction: direction,
      totalDistanceKm: totalDistanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      speedLimitKmh: speedLimitKmh,
      colorHex: colorHex,
      stops: stops ?? this.stops,
      isRoundTrip: isRoundTrip,
      active: active,
    );
  }
}

class ScheduledTripItem {
  final String id;
  final String driverId;
  final String scheduleCode; // e.g. 'TRIP-TUM-101'
  final String routeId;
  final String routeCode;
  final String routeName;
  final String origin;
  final String destination;
  final String plannedStartTime;
  final String plannedEndTime;
  final String status; // 'COMPLETED', 'ACTIVE', 'UPCOMING'
  final String routePathDescription;

  const ScheduledTripItem({
    required this.id,
    this.driverId = 'DRV_001',
    required this.scheduleCode,
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.plannedStartTime,
    required this.plannedEndTime,
    this.status = 'UPCOMING',
    this.routePathDescription = '',
  });

  ScheduledTripItem copyWith({
    String? status,
  }) {
    return ScheduledTripItem(
      id: id,
      driverId: driverId,
      scheduleCode: scheduleCode,
      routeId: routeId,
      routeCode: routeCode,
      routeName: routeName,
      origin: origin,
      destination: destination,
      plannedStartTime: plannedStartTime,
      plannedEndTime: plannedEndTime,
      status: status ?? this.status,
      routePathDescription: routePathDescription,
    );
  }

  factory ScheduledTripItem.fromJson(Map<String, dynamic> json) {
    return ScheduledTripItem(
      id: json['id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? 'DRV_001',
      scheduleCode: json['schedule_code']?.toString() ?? '',
      routeId: json['route_id']?.toString() ?? '',
      routeCode: json['route_code']?.toString() ?? 'CR101',
      routeName: json['route_name']?.toString() ?? '',
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      plannedStartTime: json['planned_start_time']?.toString() ?? '',
      plannedEndTime: json['planned_end_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'UPCOMING',
      routePathDescription: json['route_path_description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driver_id': driverId,
        'schedule_code': scheduleCode,
        'route_id': routeId,
        'route_code': routeCode,
        'route_name': routeName,
        'origin': origin,
        'destination': destination,
        'planned_start_time': plannedStartTime,
        'planned_end_time': plannedEndTime,
        'status': status,
        'route_path_description': routePathDescription,
      };
}

class DriverTrip {
  final String id;
  final String driverId;
  final BusVehicle bus;
  final TransitRoute route;
  final String? scheduleId;
  final String? inspectionId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime? destinationReachedAt;
  final TripStatus status;
  final TripLegDirection legDirection;
  final int currentStopIndex;
  final int delayMinutes;
  final int stopsCompleted;
  final int incidentsCount;

  const DriverTrip({
    required this.id,
    required this.driverId,
    required this.bus,
    required this.route,
    this.scheduleId,
    this.inspectionId,
    required this.startedAt,
    this.completedAt,
    this.destinationReachedAt,
    this.status = TripStatus.active,
    this.legDirection = TripLegDirection.outbound,
    this.currentStopIndex = 0,
    this.delayMinutes = 0,
    this.stopsCompleted = 0,
    this.incidentsCount = 0,
  });

  bool get isReturning => legDirection == TripLegDirection.returning || (route.stops.isNotEmpty && currentStopIndex >= (route.stops.length / 2).floor());

  TransitStop? get currentStop {
    if (route.stops.isEmpty) return null;
    final idx = currentStopIndex.clamp(0, route.stops.length - 1);
    return route.stops[idx];
  }

  TransitStop? get nextStop {
    if (route.stops.isEmpty) return null;
    final nextIdx = currentStopIndex + 1;
    if (nextIdx < route.stops.length) {
      return route.stops[nextIdx];
    }
    return route.stops.last;
  }

  DriverTrip copyWith({
    TripStatus? status,
    TripLegDirection? legDirection,
    int? currentStopIndex,
    DateTime? completedAt,
    DateTime? destinationReachedAt,
    int? delayMinutes,
    int? stopsCompleted,
    int? incidentsCount,
  }) {
    return DriverTrip(
      id: id,
      driverId: driverId,
      bus: bus,
      route: route,
      scheduleId: scheduleId,
      inspectionId: inspectionId,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      destinationReachedAt: destinationReachedAt ?? this.destinationReachedAt,
      status: status ?? this.status,
      legDirection: legDirection ?? this.legDirection,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      stopsCompleted: stopsCompleted ?? this.stopsCompleted,
      incidentsCount: incidentsCount ?? this.incidentsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driver_id': driverId,
        'vehicle_id': bus.id,
        'route_id': route.id,
        'schedule_id': scheduleId,
        'inspection_id': inspectionId,
        'status': status.name.toUpperCase(),
        'leg_direction': legDirection.displayName,
        'current_stop_index': currentStopIndex,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'destination_reached_at': destinationReachedAt?.toIso8601String(),
        'delay_minutes': delayMinutes,
        'stops_completed': stopsCompleted,
        'total_stops': route.stops.length,
        'incidents_count': incidentsCount,
      };
}

class TripSummary {
  final String tripId;
  final String driverId;
  final String routeCode;
  final String routeName;
  final String busNumber;
  final String origin;
  final String destination;
  final String startLocation;
  final String outboundDestination;
  final String returnLocation;
  final List<TransitStop> stops;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int delayMinutes;
  final int stopsCompleted;
  final int totalStops;
  final int incidentsCount;

  const TripSummary({
    required this.tripId,
    this.driverId = 'DRV_001',
    required this.routeCode,
    required this.routeName,
    required this.busNumber,
    required this.origin,
    required this.destination,
    this.startLocation = 'KSRTC Bus Stand',
    this.outboundDestination = 'SIT Back Gate',
    this.returnLocation = 'KSRTC Bus Stand',
    this.stops = const [],
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.delayMinutes,
    required this.stopsCompleted,
    required this.totalStops,
    this.incidentsCount = 0,
  });

  String get routeSummary => '$startLocation → $outboundDestination → $returnLocation';

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'driver_id': driverId,
        'route_code': routeCode,
        'route_name': routeName,
        'bus_number': busNumber,
        'origin': origin,
        'destination': destination,
        'start_location': startLocation,
        'outbound_destination': outboundDestination,
        'return_location': returnLocation,
        'route_summary': routeSummary,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_minutes': duration.inMinutes,
        'delay_minutes': delayMinutes,
        'stops_completed': stopsCompleted,
        'total_stops': totalStops,
        'incidents_count': incidentsCount,
      };
}
