class AdminMessage {
  final String id;
  final String? driverId;
  final String? tripId;
  final String senderType; // 'DRIVER' or 'ADMIN'
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  const AdminMessage({
    required this.id,
    this.driverId,
    this.tripId,
    required this.senderType,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  bool get isFromDriver => senderType == 'DRIVER';

  factory AdminMessage.fromJson(Map<String, dynamic> json) {
    return AdminMessage(
      id: json['id']?.toString() ?? '',
      driverId: json['driver_id']?.toString(),
      tripId: json['trip_id']?.toString(),
      senderType: json['sender_type']?.toString() ?? 'DRIVER',
      message: json['message']?.toString() ?? '',
      attachmentUrl: json['attachment_url']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driver_id': driverId,
        'trip_id': tripId,
        'sender_type': senderType,
        'message': message,
        'attachment_url': attachmentUrl,
        'created_at': createdAt.toIso8601String(),
      };
}
