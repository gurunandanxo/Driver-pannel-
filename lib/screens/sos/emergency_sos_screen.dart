import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sos_models.dart';
import '../../services/emergency_sos_service.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  final _sosService = EmergencySosService();

  @override
  void initState() {
    super.initState();
    _sosService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _sosService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showResolveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "Clear & Resolve Emergency?",
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          "This will notify Central Operations Control Center that the situation is resolved and update incident status.",
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _sosService.resolveSos(notes: "Driver confirmed situation resolved.");
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: CityRideTheme.primaryGreen),
            child: const Text("YES, SITUATION RESOLVED"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sos = _sosService.activeSos;
    final status = sos?.status ?? SosStatus.triggered;
    final contacts = _sosService.contacts;

    return Scaffold(
      backgroundColor: const Color(0xFF450A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sos?.id ?? "SOS-ACTIVE",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Emergency Icon with Glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.6),
                      blurRadius: 25,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.emergency_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                "CRITICAL EMERGENCY ACTIVE",
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "GPS Coordinates transmitted to Central OCC & Emergency Services",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Stepper Progression Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF991B1B)),
                ),
                child: Column(
                  children: [
                    _buildStepRow(
                      number: "1",
                      title: "SOS BROADCASTED",
                      subtitle: "Vehicle & GPS coordinates sent to Control Room",
                      isDone: true,
                    ),
                    const Divider(color: Color(0xFF991B1B), height: 16),
                    _buildStepRow(
                      number: "2",
                      title: "OCC DISPATCH ACKNOWLEDGED",
                      subtitle: sos?.acknowledgedByDispatcher ?? "Awaiting dispatcher acknowledgment...",
                      isDone: status.index >= SosStatus.acknowledged.index,
                    ),
                    const Divider(color: Color(0xFF991B1B), height: 16),
                    _buildStepRow(
                      number: "3",
                      title: "EMERGENCY UNITS DISPATCHED",
                      subtitle: sos?.resolutionNotes ?? "Support units on standby",
                      isDone: status.index >= SosStatus.responding.index,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Direct Calling Emergency Contacts Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "DIRECT EMERGENCY SPEED DIAL",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Contacts Speed Dial List
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                contact.phone,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _sosService.callEmergencyContact(contact.phone),
                            icon: const Icon(Icons.call, size: 16, color: Colors.white),
                            label: const Text("CALL"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Resolve Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _showResolveDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7F1D1D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "MARK SITUATION RESOLVED",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF16A34A) : Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
