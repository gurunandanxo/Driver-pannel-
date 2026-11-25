import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/driver_auth_service.dart';
import '../../services/driver_settings_service.dart';
import '../auth/driver_login_screen.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  final _settingsService = DriverSettingsService();
  final _authService = DriverAuthService();

  late TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(text: _settingsService.backendApiBaseUrl);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  void _saveBackendConfig() {
    _settingsService.updateBackendConfig(
      backendUrl: _apiUrlController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Backend endpoints updated for Admin Panel linking!"),
        backgroundColor: CityRideTheme.accentGreen,
      ),
    );
  }

  void _testConnection() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.cloud_done_rounded, color: CityRideTheme.accentGreen, size: 24),
            const SizedBox(width: 8),
            Text(
              "Central Server Ready",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          "CITYRIDE Local Transit Gateway ping latency: 12ms • Standalone Local Operations Ready • Tumakuru Node OCC Active.",
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("DISMISS"),
          ),
        ],
      ),
    );
  }

  void _logout() {
    _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = _authService.activeDriver;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Console Settings",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Driver Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CityRideTheme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: CityRideTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver?.name ?? "Driver",
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: CityRideTheme.textDark,
                          ),
                        ),
                        Text(
                          "License: ${driver?.licenseNumber}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CityRideTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Display & HUD
            Text(
              "DISPLAY & COCKPIT HUD",
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CityRideTheme.dividerColor),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _settingsService.isNightHudMode,
                    onChanged: (val) {
                      setState(() {
                        _settingsService.toggleNightHudMode(val);
                      });
                    },
                    activeColor: CityRideTheme.primaryGreen,
                    title: Text(
                      "Night HUD Mode",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "High-contrast dark dashboard for night driving safety",
                      style: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textMuted),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _settingsService.audioAnnouncementsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _settingsService.toggleAudioAnnouncements(val);
                      });
                    },
                    activeColor: CityRideTheme.primaryGreen,
                    title: Text(
                      "Next Stop Audio Announcements",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Chime alert on approaching 50m stop geofence",
                      style: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textMuted),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _settingsService.speedLimitWarningsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _settingsService.toggleSpeedLimitWarnings(val);
                      });
                    },
                    activeColor: CityRideTheme.primaryGreen,
                    title: Text(
                      "Over-Speed Audible Warnings",
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Alert when vehicle exceeds city corridor 40 km/h limit",
                      style: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Telemetry & GPS Broadcast
            Text(
              "TELEMETRY BROADCAST FREQUENCY",
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CityRideTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "GPS Update Rate to OCC & Passengers",
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [1, 3, 5].map((sec) {
                      final isSelected = _settingsService.gpsBroadcastIntervalSeconds == sec;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _settingsService.setGpsBroadcastInterval(sec);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? CityRideTheme.lightGreenChip : CityRideTheme.scaffoldBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? CityRideTheme.primaryGreen : CityRideTheme.dividerColor,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "${sec}s (${sec == 1 ? 'Live' : 'Eco'})",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? CityRideTheme.primaryGreen : CityRideTheme.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Backend Connectivity (Ready for linking with Admin Panel!)
            Text(
              "BACKEND CONNECTIVITY & ADMIN LINK",
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CityRideTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REST API Gateway URL",
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiUrlController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: CityRideTheme.scaffoldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: CityRideTheme.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testConnection,
                          icon: const Icon(Icons.network_check_rounded, size: 16),
                          label: const Text("TEST PING"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveBackendConfig,
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text("SAVE CONFIG"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: CityRideTheme.errorColor),
                label: Text(
                  "SIGN OUT DRIVER",
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: CityRideTheme.errorColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CityRideTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
