import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/driver_models.dart';
import '../../services/driver_auth_service.dart';
import '../../services/driver_settings_service.dart';
import '../admin/contact_admin_screen.dart';
import '../auth/driver_login_screen.dart';
import '../auth/forgot_password_modal.dart';

class DriverProfileScreen extends StatefulWidget {
  final bool isEmbeddedTab;

  const DriverProfileScreen({
    super.key,
    this.isEmbeddedTab = false,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _authService = DriverAuthService();
  final _settingsService = DriverSettingsService();
  final _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onStateChanged);
    _settingsService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onStateChanged);
    _settingsService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      setState(() => _isUploadingPhoto = true);
      await _authService.updateProfilePhoto(image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully.'),
            backgroundColor: CityRideTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('[DriverProfile] Photo upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Sign Out of Console?",
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Are you sure you want to end your current session? You will need your Driver credentials to log back in.",
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CityRideTheme.errorColor),
            child: const Text("SIGN OUT"),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Text(content, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = _authService.activeDriver;
    final isDark = _settingsService.isNightHudMode;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: widget.isEmbeddedTab
          ? null
          : AppBar(
              title: Text(
                "Driver Profile",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CityRideTheme.textDark,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: CityRideTheme.textDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: SafeArea(
        top: !widget.isEmbeddedTab,
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 12, 18, widget.isEmbeddedTab ? 110 : 12),
          children: [
            // Driver Profile Header Card with Avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                boxShadow: [
                  BoxShadow(
                    color: CityRideTheme.primaryGreen.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: CityRideTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: CityRideTheme.primaryGreen.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: driver?.profilePhotoUrl != null && driver!.profilePhotoUrl!.isNotEmpty
                              ? Image.network(
                                  driver.profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildInitials(driver),
                                )
                              : _buildInitials(driver),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: CityRideTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driver?.name ?? "Driver",
                    style: GoogleFonts.inter(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: CityRideTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        driver?.driverId ?? 'TUM-DRV-1042',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CityRideTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text("•", style: GoogleFonts.inter(color: CityRideTheme.textLight)),
                      const SizedBox(width: 6),
                      Text(
                        driver?.role ?? 'Senior Driver',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 1: Personal Information
            _buildSectionHeader("PERSONAL INFORMATION"),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CityRideTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildProfileTile(Icons.person_outline_rounded, "Full Name", driver?.name ?? "Ramesh Gowda"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.phone_outlined, "Mobile Number", driver?.phone ?? "+91 98450 12345"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.email_outlined, "Email Address", driver?.email ?? "ramesh.gowda@cityride.in"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.location_on_outlined, "Residential Address", "${driver?.address ?? '14th Cross, SIT Main Road'}, ${driver?.city ?? 'Tumakuru'}"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(
                      Icons.contact_emergency_outlined,
                      "Emergency Contact",
                      "${driver?.emergencyContactName ?? 'Smt. Suma Gowda'} (${driver?.emergencyContactNumber ?? '+91 98450 99887'})",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 2: Driver Information
            _buildSectionHeader("DRIVER INFORMATION"),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CityRideTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildProfileTile(Icons.badge_outlined, "Driver ID", driver?.driverId ?? "TUM-DRV-1042"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.credit_card_outlined, "Licence Number", driver?.licenseNumber ?? "KA-06-2012-0048291"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.event_outlined, "Licence Expiry", driver?.licenseExpiry ?? "2028-06-14"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.military_tech_outlined, "Experience", driver?.experience ?? "10+ Years"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.directions_bus_outlined, "Driver Category", driver?.driverCategory ?? "Heavy Passenger Vehicle (HPV)"),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildProfileTile(Icons.store_mall_directory_outlined, "Assigned Depot", driver?.depotName ?? "Tumakuru Central City Depot #1"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Section 3: Account & Security
            _buildSectionHeader("ACCOUNT & SECURITY"),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CityRideTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      Icons.lock_reset_rounded,
                      "Change Password",
                      () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ForgotPasswordModal(),
                        );
                      },
                    ),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    SwitchListTile(
                      value: isDark,
                      onChanged: (val) => _settingsService.toggleNightHudMode(val),
                      activeColor: CityRideTheme.primaryGreen,
                      title: Text(
                        "Night Mode HUD",
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
                      ),
                      subtitle: Text(
                        "High-contrast dark theme for night shifts",
                        style: GoogleFonts.inter(fontSize: 11.5, color: CityRideTheme.textMuted),
                      ),
                    ),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildActionTile(
                      Icons.support_agent_rounded,
                      "Help & Support / Contact Admin",
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactAdminScreen())),
                    ),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildActionTile(
                      Icons.description_outlined,
                      "Terms & Conditions",
                      () => _showInfoDialog(
                        "Terms & Conditions",
                        "CityRide Driver Operational Policies:\n1. Pre-trip safety audits are mandatory prior to operating transit buses.\n2. GPS telemetry and geofencing must remain enabled throughout the shift.\n3. Drivers must adhere to corridor speed limits and official stop schedules.",
                      ),
                    ),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildActionTile(
                      Icons.privacy_tip_outlined,
                      "Privacy Policy",
                      () => _showInfoDialog(
                        "Privacy Policy",
                        "CityRide collects GPS telemetry, route progress, and operational logs strictly for fleet management, public passenger ETA calculation, and safety auditing in accordance with Karnataka Smart City Transit guidelines.",
                      ),
                    ),
                    const Divider(height: 1, color: CityRideTheme.dividerColor),
                    _buildActionTile(
                      Icons.info_outline_rounded,
                      "About CityRide",
                      () => _showInfoDialog(
                        "About CityRide Driver Console",
                        "CITYRIDE Smart Public Transportation Platform\nVersion: ${AppConfig.appVersion}\nTumakuru City Transit Console\nDeveloped for Driver Operations & Central OCC Dispatch.",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  "SIGN OUT",
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.errorColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(DriverProfile? driver) {
    return Center(
      child: Text(
        driver?.initials ?? 'D',
        style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CityRideTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: CityRideTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: CityRideTheme.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 18, color: CityRideTheme.primaryGreen),
      title: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: CityRideTheme.textMuted),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
