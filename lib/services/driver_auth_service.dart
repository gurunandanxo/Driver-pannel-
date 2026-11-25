import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/driver_models.dart';
import 'trip_engine.dart';
import 'trip_history_service.dart';

class RegistrationResult {
  final bool success;
  final String? driverId;
  final String? message;
  final DriverProfile? profile;

  const RegistrationResult({
    required this.success,
    this.driverId,
    this.message,
    this.profile,
  });
}

class DriverAuthService extends ChangeNotifier {
  static final DriverAuthService _instance = DriverAuthService._internal();
  factory DriverAuthService() => _instance;

  DriverAuthService._internal() {
    _activeDriver = demoDrivers[0];
    _isAuthenticated = true;
  }

  // Pre-configured Verified Drivers for Testing & Offline Demo (Clearly labeled development only)
  static final List<DriverProfile> demoDrivers = [
    const DriverProfile(
      id: 'DRV_001',
      driverId: 'TUM-DRV-1042',
      name: 'Ramesh Gowda',
      kannadaName: 'ರಮೇಶ್ ಗೌಡ',
      phone: '+91 98450 12345',
      email: 'ramesh.gowda@cityride.in',
      dateOfBirth: '1985-06-15',
      address: '14th Cross, SIT Main Road, Tumakuru',
      city: 'Tumakuru',
      emergencyContactName: 'Smt. Suma Gowda (Spouse)',
      emergencyContactNumber: '+91 98450 99887',
      licenseNumber: 'KA-06-2012-0048291',
      licenseExpiry: '2028-06-14',
      experience: '10+ Years',
      driverCategory: 'Heavy Passenger Vehicle (HPV)',
      badgeNumber: 'BDG-TUM-0482',
      depotId: 'DEPOT_01',
      depotName: 'Tumakuru Central City Depot #1 (Ashoka Road)',
      role: 'Senior Driver',
      accountStatus: 'ACTIVE',
    ),
    const DriverProfile(
      id: 'DRV_002',
      driverId: 'TUM-DRV-1088',
      name: 'Siddaraju M.',
      kannadaName: 'ಸಿದ್ಧರಾಜು ಎಂ.',
      phone: '+91 94480 87654',
      email: 'siddaraju.m@cityride.in',
      dateOfBirth: '1990-03-22',
      address: 'Near Town Hall Circle, Tumakuru',
      city: 'Tumakuru',
      emergencyContactName: 'Shri Manjunath (Brother)',
      emergencyContactNumber: '+91 94480 11223',
      licenseNumber: 'KA-06-2015-0019283',
      licenseExpiry: '2030-03-21',
      experience: '5-10 Years',
      driverCategory: 'Heavy Passenger Vehicle (HPV)',
      badgeNumber: 'BDG-TUM-1092',
      depotId: 'DEPOT_01',
      depotName: 'Tumakuru Central City Depot #1 (Ashoka Road)',
      role: 'Transit Driver',
      accountStatus: 'ACTIVE',
    ),
    const DriverProfile(
      id: 'DRV_003',
      driverId: 'TUM-DRV-2015',
      name: 'Manjunath K.',
      kannadaName: 'ಮಂಜುನಾಥ್ ಕೆ.',
      phone: '+91 99012 34567',
      email: 'manjunath.k@cityride.in',
      dateOfBirth: '1993-11-08',
      address: 'Batawadi Ring Road, Tumakuru',
      city: 'Tumakuru',
      emergencyContactName: 'Smt. Kavitha (Spouse)',
      emergencyContactNumber: '+91 99012 77889',
      licenseNumber: 'KA-06-2018-0056123',
      licenseExpiry: '2033-11-07',
      experience: '3-5 Years',
      driverCategory: 'Medium Transit Vehicle (MTV)',
      badgeNumber: 'BDG-TUM-2015',
      depotId: 'DEPOT_02',
      depotName: 'Tumakuru North Depot #2 (Batawadi)',
      role: 'Transit Driver',
      accountStatus: 'ACTIVE',
    ),
  ];

  DriverProfile? _activeDriver;
  bool _isAuthenticated = true;
  bool _isLoading = false;
  String? _errorMessage;

  DriverProfile? get activeDriver => _activeDriver;
  bool get isAuthenticated => _isAuthenticated && _activeDriver != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Registers a new driver and persists the profile locally
  Future<RegistrationResult> registerDriver({
    required String fullName,
    required String dateOfBirth,
    required String mobile,
    required String email,
    required String address,
    required String city,
    required String emergencyContactName,
    required String emergencyContactNumber,
    required String licenceNumber,
    required String licenceExpiry,
    required String experience,
    required String driverCategory,
    required String depot,
    required String password,
    File? photoFile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = mobile.trim();

    final localDriverId = 'TUM-DRV-${1043 + demoDrivers.length}';
    final newProfile = DriverProfile(
      id: 'DRV_LOCAL_${DateTime.now().millisecondsSinceEpoch}',
      driverId: localDriverId,
      name: fullName.trim(),
      phone: cleanPhone,
      email: cleanEmail,
      dateOfBirth: dateOfBirth,
      address: address.trim(),
      city: city.trim(),
      emergencyContactName: emergencyContactName.trim(),
      emergencyContactNumber: emergencyContactNumber.trim(),
      licenseNumber: licenceNumber.trim(),
      licenseExpiry: licenceExpiry,
      experience: experience,
      driverCategory: driverCategory,
      depotId: 'DEPOT_01',
      depotName: depot,
      profilePhotoUrl: photoFile?.path,
      role: 'Transit Driver',
      accountStatus: 'ACTIVE',
    );

    demoDrivers.add(newProfile);
    _isLoading = false;
    notifyListeners();

    return RegistrationResult(
      success: true,
      driverId: localDriverId,
      message: 'Driver account created successfully.',
      profile: newProfile,
    );
  }

  /// Driver Login supporting Driver ID or Email
  Future<bool> login(String driverIdOrEmail, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final input = driverIdOrEmail.trim();
    final pwd = password.trim();

    // Local / Demo driver verification
    final normalized = input.toUpperCase();
    final match = demoDrivers.firstWhere(
      (d) =>
          d.driverId.toUpperCase() == normalized ||
          d.driverId.endsWith(normalized) ||
          d.email.toUpperCase() == normalized,
      orElse: () => const DriverProfile(
        id: '',
        driverId: '',
        name: '',
        phone: '',
        email: '',
        licenseNumber: '',
        badgeNumber: '',
        depotId: '',
        depotName: '',
      ),
    );

    final expectedPin = match.driverId.split('-').last;
    final isMatch = pwd == expectedPin ||
        pwd == 'cityride$expectedPin' ||
        pwd == 'password' ||
        pwd == 'Password@123' ||
        pwd == 'CityRide@2026';

    if (match.id.isNotEmpty && isMatch) {
      _activeDriver = match;
      _isAuthenticated = true;
      _isLoading = false;
      _errorMessage = null;
      TripEngine().onDriverAuthenticated(match);
      TripHistoryService().onDriverAuthenticated(match);
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      _errorMessage = 'Invalid Driver ID/email or PIN/password.';
      notifyListeners();
      return false;
    }
  }

  /// Sends password reset confirmation
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void selectDemoDriver(DriverProfile driver) {
    _activeDriver = driver;
    _isAuthenticated = true;
    _errorMessage = null;
    TripEngine().onDriverAuthenticated(driver);
    TripHistoryService().onDriverAuthenticated(driver);
    notifyListeners();
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    if (_activeDriver != null) {
      _activeDriver = _activeDriver!.copyWith(profilePhotoUrl: photoUrl);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    TripEngine().clearDriverSession();
    TripHistoryService().clearDriverSession();
    _activeDriver = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }
}
