import 'package:flutter/foundation.dart';

class DriverSettingsService extends ChangeNotifier {
  static final DriverSettingsService _instance = DriverSettingsService._internal();
  factory DriverSettingsService() => _instance;
  DriverSettingsService._internal();

  bool _isNightHudMode = false;
  bool _audioAnnouncementsEnabled = true;
  bool _speedLimitWarningsEnabled = true;
  int _gpsBroadcastIntervalSeconds = 1;
  String _backendApiBaseUrl = 'https://api.cityride-tumkur.gov.in/v1';

  bool get isNightHudMode => _isNightHudMode;
  bool get audioAnnouncementsEnabled => _audioAnnouncementsEnabled;
  bool get speedLimitWarningsEnabled => _speedLimitWarningsEnabled;
  int get gpsBroadcastIntervalSeconds => _gpsBroadcastIntervalSeconds;
  String get backendApiBaseUrl => _backendApiBaseUrl;

  void toggleNightHudMode(bool enabled) {
    _isNightHudMode = enabled;
    notifyListeners();
  }

  void toggleAudioAnnouncements(bool enabled) {
    _audioAnnouncementsEnabled = enabled;
    notifyListeners();
  }

  void toggleSpeedLimitWarnings(bool enabled) {
    _speedLimitWarningsEnabled = enabled;
    notifyListeners();
  }

  void setGpsBroadcastInterval(int seconds) {
    _gpsBroadcastIntervalSeconds = seconds;
    notifyListeners();
  }

  void updateBackendConfig({
    required String backendUrl,
  }) {
    _backendApiBaseUrl = backendUrl;
    notifyListeners();
  }
}
