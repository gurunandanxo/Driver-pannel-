import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _notifService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notifService.notifications;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Alerts & Notifications",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _notifService.markAllAsRead(),
            child: Text(
              "MARK ALL READ",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "No notifications",
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final timeStr = DateFormat('hh:mm a, dd MMM').format(notif.createdAt);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: notif.isRead ? CityRideTheme.dividerColor : CityRideTheme.accentGreen.withOpacity(0.5),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _notifService.markAsRead(notif.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: notif.isRead ? const Color(0xFFF1F5F9) : CityRideTheme.lightGreenChip,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notif.type == 'TRIP'
                                ? Icons.directions_bus_rounded
                                : (notif.type == 'INSPECTION' ? Icons.checklist_rounded : Icons.info_outline_rounded),
                            size: 18,
                            color: CityRideTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700,
                                        color: CityRideTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: CityRideTheme.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: CityRideTheme.textDark.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeStr,
                                style: GoogleFonts.inter(fontSize: 11, color: CityRideTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
