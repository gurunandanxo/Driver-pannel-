import 'package:flutter/foundation.dart';
import '../models/driver_models.dart';
import '../models/trip_models.dart';

enum HistoryFilter {
  today,
  yesterday,
  thisWeek,
  thisMonth,
}

extension HistoryFilterExtension on HistoryFilter {
  String get displayName {
    switch (this) {
      case HistoryFilter.today:
        return 'TODAY';
      case HistoryFilter.yesterday:
        return 'YESTERDAY';
      case HistoryFilter.thisWeek:
        return 'THIS WEEK';
      case HistoryFilter.thisMonth:
        return 'THIS MONTH';
    }
  }
}

class TripHistoryService extends ChangeNotifier {
  static final TripHistoryService _instance = TripHistoryService._internal();
  factory TripHistoryService() => _instance;

  TripHistoryService._internal() {
    _loadSampleHistoricalTrips();
  }

  String? _currentDriverId;
  final List<TripSummary> _historyRecords = [];
  HistoryFilter _currentFilter = HistoryFilter.today;
  final bool _isLoading = false;

  // Driver-scoped history cache
  static final Map<String, List<TripSummary>> _driverHistoryCache = {};

  List<TripSummary> get allRecords => List.unmodifiable(_historyRecords);
  HistoryFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;

  void onDriverAuthenticated(DriverProfile driver) {
    _currentDriverId = driver.id;
    _historyRecords.clear();
    if (_driverHistoryCache.containsKey(driver.id)) {
      _historyRecords.addAll(_driverHistoryCache[driver.id]!);
    } else {
      _loadSampleHistoricalTripsForDriver(driver.id);
    }
    notifyListeners();
    fetchHistoryFromCloud(driver.id);
  }

  void clearDriverSession() {
    if (_currentDriverId != null) {
      _driverHistoryCache[_currentDriverId!] = List.from(_historyRecords);
    }
    _currentDriverId = null;
    _historyRecords.clear();
    notifyListeners();
  }

  List<TripSummary> get filteredRecords {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    switch (_currentFilter) {
      case HistoryFilter.today:
        return _historyRecords.where((t) => t.startTime.isAfter(todayStart)).toList();
      case HistoryFilter.yesterday:
        return _historyRecords.where((t) => t.startTime.isAfter(yesterdayStart) && t.startTime.isBefore(todayStart)).toList();
      case HistoryFilter.thisWeek:
        return _historyRecords.where((t) => t.startTime.isAfter(weekStart)).toList();
      case HistoryFilter.thisMonth:
        return _historyRecords.where((t) => t.startTime.isAfter(monthStart)).toList();
    }
  }

  void setFilter(HistoryFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void addCompletedRecord(TripSummary summary) {
    _historyRecords.insert(0, summary);
    if (_currentDriverId != null) {
      _driverHistoryCache[_currentDriverId!] = List.from(_historyRecords);
    }
    notifyListeners();
  }

  Future<void> fetchHistoryFromCloud([String? targetDriverId]) async {
    // Standalone local operations mode
  }

  void _loadSampleHistoricalTrips() {
    _loadSampleHistoricalTripsForDriver('DRV_001');
  }

  void _loadSampleHistoricalTripsForDriver(String driverId) {
    final now = DateTime.now();
    _historyRecords.clear();

    if (driverId == 'DRV_001') {
      _historyRecords.add(TripSummary(
        tripId: 'TRIP_TUM_0901',
        driverId: 'DRV_001',
        routeCode: 'CR101',
        routeName: 'KSRTC Stand ↔ SIT Circular Loop',
        busNumber: 'KA06F8558',
        origin: 'KSRTC Bus Stand',
        destination: 'KSRTC Bus Stand',
        startLocation: 'KSRTC Bus Stand',
        outboundDestination: 'SIT Back Gate',
        returnLocation: 'KSRTC Bus Stand',
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(const Duration(hours: 2, minutes: 32)),
        duration: const Duration(minutes: 28),
        delayMinutes: 0,
        stopsCompleted: 11,
        totalStops: 11,
        incidentsCount: 0,
      ));
      _historyRecords.add(TripSummary(
        tripId: 'TRIP_TUM_0899',
        driverId: 'DRV_001',
        routeCode: 'CR102',
        routeName: 'KSRTC → SIT Back Gate → KSRTC',
        busNumber: 'KA06F8558',
        origin: 'KSRTC Bus Stand',
        destination: 'KSRTC Bus Stand',
        startLocation: 'KSRTC Bus Stand',
        outboundDestination: 'SIT Back Gate',
        returnLocation: 'KSRTC Bus Stand',
        startTime: now.subtract(const Duration(days: 1, hours: 4)),
        endTime: now.subtract(const Duration(days: 1, hours: 3, minutes: 36)),
        duration: const Duration(minutes: 24),
        delayMinutes: 2,
        stopsCompleted: 5,
        totalStops: 5,
        incidentsCount: 0,
      ));
    } else if (driverId == 'DRV_002') {
      _historyRecords.add(TripSummary(
        tripId: 'TRIP_TUM_0701',
        driverId: 'DRV_002',
        routeCode: 'CR103',
        routeName: 'KSRTC ↔ Melekote Industrial Loop',
        busNumber: 'KA06F9200',
        origin: 'KSRTC Bus Stand',
        destination: 'KSRTC Bus Stand',
        startLocation: 'KSRTC Bus Stand',
        outboundDestination: 'Melekote Cross',
        returnLocation: 'KSRTC Bus Stand',
        startTime: now.subtract(const Duration(hours: 4)),
        endTime: now.subtract(const Duration(hours: 3, minutes: 28)),
        duration: const Duration(minutes: 32),
        delayMinutes: 0,
        stopsCompleted: 5,
        totalStops: 5,
        incidentsCount: 0,
      ));
    } else if (driverId == 'DRV_003') {
      _historyRecords.add(TripSummary(
        tripId: 'TRIP_TUM_0601',
        driverId: 'DRV_003',
        routeCode: 'CR201',
        routeName: 'Batawadi ↔ Kyathsandra Loop',
        busNumber: 'KA06F1122',
        origin: 'Batawadi Circle',
        destination: 'Batawadi Circle',
        startLocation: 'Batawadi Circle',
        outboundDestination: 'Kyathsandra Temple',
        returnLocation: 'Batawadi Circle',
        startTime: now.subtract(const Duration(hours: 5)),
        endTime: now.subtract(const Duration(hours: 4, minutes: 30)),
        duration: const Duration(minutes: 30),
        delayMinutes: 1,
        stopsCompleted: 5,
        totalStops: 5,
        incidentsCount: 0,
      ));
    }

    _driverHistoryCache[driverId] = List.from(_historyRecords);
  }
}
