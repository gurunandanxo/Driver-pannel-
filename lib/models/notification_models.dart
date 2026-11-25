class DriverNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'TRIP', 'INSPECTION', 'ALERT', 'ADMIN', 'SYSTEM'
  final bool isRead;
  final DateTime createdAt;

  const DriverNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'INFO',
    this.isRead = false,
    required this.createdAt,
  });

  DriverNotification copyWith({
    bool? isRead,
  }) {
    return DriverNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'INFO',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? driverId}) => {
        'id': id,
        'driver_id': driverId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}
