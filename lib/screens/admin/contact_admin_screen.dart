import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../services/admin_communication_service.dart';

class ContactAdminScreen extends StatefulWidget {
  const ContactAdminScreen({super.key});

  @override
  State<ContactAdminScreen> createState() => _ContactAdminScreenState();
}

class _ContactAdminScreenState extends State<ContactAdminScreen> {
  final _commService = AdminCommunicationService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _commService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _commService.removeListener(_onStateChanged);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleSendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await _commService.sendMessage(messageText: text);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _callAdminHotline() async {
    final uri = Uri.parse('tel:08162278000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _commService.messages;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Admin & OCC Dispatch",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: CityRideTheme.primaryGreen),
            tooltip: "Call Central OCC Hotline",
            onPressed: _callAdminHotline,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Admin Hotline Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: CityRideTheme.routePlannerBg,
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 20, color: CityRideTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Direct link to Central Operations & Shift Supervisor (0816-2278000)",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CityRideTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages Conversation Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isDriver = msg.isFromDriver;
                  final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

                  return Align(
                    alignment: isDriver ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDriver ? CityRideTheme.primaryGreen : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isDriver ? 14 : 2),
                          bottomRight: Radius.circular(isDriver ? 2 : 14),
                        ),
                        border: isDriver ? null : Border.all(color: CityRideTheme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDriver ? "You" : "OCC Dispatcher",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDriver ? Colors.white.withOpacity(0.8) : CityRideTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            msg.message,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: isDriver ? Colors.white : CityRideTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              timeStr,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: isDriver ? Colors.white.withOpacity(0.7) : CityRideTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message Composer Dock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: CityRideTheme.dividerColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Type operational message or request...",
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: CityRideTheme.textLight),
                        filled: true,
                        fillColor: CityRideTheme.scaffoldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _commService.isSending ? null : _handleSendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: CityRideTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _commService.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
