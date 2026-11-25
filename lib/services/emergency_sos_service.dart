import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_models.dart';
import 'driver_auth_service.dart';
import 'gps_service.dart';

class EmergencySosService extends ChangeNotifier {
  static final EmergencySosService _instance = EmergencySosService._internal();
  factory EmergencySosService() => _instance;

  EmergencySosService._internal();

  EmergencySosAlert? _activeSos;
  final List<EmergencyContact> _contacts = EmergencyContact.defaultContacts;
  bool _isSosActive = false;

  EmergencySosAlert? get activeSos => _activeSos;
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  bool get isSosActive => _isSosActive;

  Future<void> triggerSos({
    String? tripId,
    String? vehicleId,
    String? routeId,
    String? routeName,
  }) async {
    final driver = DriverAuthService().activeDriver;
    final gps = GpsService();

    final alert = EmergencySosAlert(
      id: 'SOS_${DateTime.now().millisecondsSinceEpoch}',
      tripId: tripId ?? 'TRIP_ACTIVE',
      driverId: driver?.id ?? 'DRV_ANON',
      driverName: driver?.name ?? 'Driver',
      vehicleId: vehicleId ?? 'BUS_TUM_001',
      vehicleReg: vehicleId ?? 'KA06F8558',
      routeId: routeId ?? 'ROUTE_CR101',
      routeName: routeName ?? 'Route 1',
      latitude: gps.latitude,
      longitude: gps.longitude,
      speedKmh: gps.speedKmh,
      triggeredAt: DateTime.now(),
      status: SosStatus.triggered,
    );

    _activeSos = alert;
    _isSosActive = true;
    notifyListeners();
  }

  Future<bool> callEmergencyContact(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      debugPrint('[EmergencySosService] Dialing error: $e');
    }
    return false;
  }

  void resolveSos({String? notes}) {
    if (_activeSos != null) {
      _activeSos = _activeSos!.copyWith(
        status: SosStatus.resolved,
        resolutionNotes: notes ?? 'Driver verified safe status',
      );
      _isSosActive = false;
      notifyListeners();
    }
  }
}
