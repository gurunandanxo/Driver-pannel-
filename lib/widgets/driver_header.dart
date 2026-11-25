import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/driver_models.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/driver_profile_screen.dart';
import '../services/driver_auth_service.dart';
import '../services/notification_service.dart';
import 'cityride_logo.dart';

class DriverHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onProfileTap;

  const DriverHeader({
    super.key,
    this.isDark = false,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final authService = DriverAuthService();
    final notifService = NotificationService();
    final driver = authService.activeDriver;
    final unreadCount = notifService.unreadCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: CITYRIDE | DRIVER Brand Logo
            const CityRideDriverLogo(size: 30),

            // Right: ALERT Notification Icon + PROFILE Photo Avatar
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Alert Button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? Colors.white : CityRideTheme.textDark,
                        size: 22,
                      ),
                      tooltip: "Alerts & Notifications",
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: CityRideTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),

                // Profile Avatar Button
                InkWell(
                  onTap: () {
                    if (onProfileTap != null) {
                      onProfileTap!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: CityRideTheme.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? CityRideTheme.accentGreen : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(DriverProfile? driver) {
    return Center(
      child: Text(
        driver?.initials ?? 'D',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
