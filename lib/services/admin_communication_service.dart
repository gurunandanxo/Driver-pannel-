import 'package:flutter/foundation.dart';
import '../models/admin_message_models.dart';
import 'driver_auth_service.dart';

class AdminCommunicationService extends ChangeNotifier {
  static final AdminCommunicationService _instance = AdminCommunicationService._internal();
  factory AdminCommunicationService() => _instance;

  AdminCommunicationService._internal() {
    _loadSampleMessages();
  }

  final List<AdminMessage> _messages = [];
  bool _isSending = false;

  List<AdminMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  Future<bool> sendMessage({
    required String messageText,
    String? tripId,
    String? attachmentUrl,
  }) async {
    _isSending = true;
    notifyListeners();

    final driver = DriverAuthService().activeDriver;
    final newMsg = AdminMessage(
      id: 'MSG_${DateTime.now().millisecondsSinceEpoch}',
      driverId: driver?.id,
      tripId: tripId,
      senderType: 'DRIVER',
      message: messageText.trim(),
      attachmentUrl: attachmentUrl,
      createdAt: DateTime.now(),
    );

    _messages.add(newMsg);

    _isSending = false;
    notifyListeners();
    return true;
  }

  void _loadSampleMessages() {
    _messages.add(
      AdminMessage(
        id: 'MSG_001',
        senderType: 'ADMIN',
        message: 'Welcome to your shift. All route coordinates and geofences for Tumakuru Corridor have been calibrated.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    );
  }
}
