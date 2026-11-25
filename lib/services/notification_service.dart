import 'package:flutter/foundation.dart';
import '../models/notification_models.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal() {
    _loadSampleNotifications();
  }

  final List<DriverNotification> _notifications = [];

  List<DriverNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String message,
    String type = 'INFO',
  }) {
    final notif = DriverNotification(
      id: 'NOTIF_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    notifyListeners();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void _loadSampleNotifications() {
    _notifications.addAll([
      DriverNotification(
        id: 'NOTIF_01',
        title: 'Duty Assignment Active',
        message: 'You are assigned to Route CR101 for the Morning Shift.',
        type: 'TRIP',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      DriverNotification(
        id: 'NOTIF_02',
        title: 'Pre-Trip Safety Reminder',
        message: 'Ensure full 5-point safety inspection before departing from central depot.',
        type: 'INSPECTION',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);
  }
}
