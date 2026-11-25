import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// State-aware Vehicle Assignment Module for the CityRide Driver Dashboard.
///
/// Implements two distinct operational presentations:
/// 1. Unverified State (isBusVerified == false):
///    - Header: Bus icon + "VEHICLE ASSIGNMENT" + "Bus Required" badge.
///    - Instructional subtitle.
///    - Registration number input field with pre-fill e.g. "KA06F8558".
///    - Full-width [ VERIFY BUS ] primary button.
///    - Inline error feedback and loading indicator.
///
/// 2. Verified State (isBusVerified == true):
///    - Compact vehicle status section.
///    - Header: Bus icon + "YOUR BUS" + "🟢 VERIFIED" badge.
///    - Large bold registration number e.g. "KA06F8558".
///    - Depot information e.g. "Tumakuru Depot #1 • Vehicle Ready".
///    - Small [CHANGE BUS] option to re-enter registration number if needed.
class VehicleAssignmentModule extends StatefulWidget {
  final bool isBusVerified;
  final String? busNumber;
  final String? depotName;
  final bool isLoading;
  final String? errorMessage;
  final Function(String busNumber) onVerify;
  final VoidCallback onChangeBus;

  const VehicleAssignmentModule({
    super.key,
    required this.isBusVerified,
    this.busNumber,
    this.depotName,
    this.isLoading = false,
    this.errorMessage,
    required this.onVerify,
    required this.onChangeBus,
  });

  @override
  State<VehicleAssignmentModule> createState() => _VehicleAssignmentModuleState();
}

class _VehicleAssignmentModuleState extends State<VehicleAssignmentModule> {
  late TextEditingController _busController;

  @override
  void initState() {
    super.initState();
    _busController = TextEditingController(text: widget.busNumber ?? 'KA06F8558');
  }

  @override
  void didUpdateWidget(covariant VehicleAssignmentModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busNumber != null && widget.busNumber != oldWidget.busNumber) {
      _busController.text = widget.busNumber!;
    }
  }

  @override
  void dispose() {
    _busController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBusVerified) {
      return _buildVerifiedCard();
    } else {
      return _buildUnverifiedCard();
    }
  }

  Widget _buildVerifiedCard() {
    final displayBus = widget.busNumber ?? 'KA06F8558';
    final displayDepot = widget.depotName ?? 'Tumakuru Depot #1';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: Bus icon + "YOUR BUS" + "VERIFIED" badge + "CHANGE BUS" button
          Row(
            children: [
              const Icon(
                Icons.directions_bus_rounded,
                size: 16,
                color: Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Text(
                "YOUR BUS",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  "🟢 VERIFIED",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.onChangeBus,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    "CHANGE BUS",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: CityRideTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Primary registration plate
          Text(
            displayBus,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),

          // Subline: Depot & readiness
          Text(
            "$displayDepot • Vehicle Ready",
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnverifiedCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.errorMessage != null ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: Bus icon + VEHICLE ASSIGNMENT + Bus Required badge
          Row(
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                size: 18,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                "VEHICLE ASSIGNMENT",
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  "Bus Required",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            "Enter your assigned transit bus registration number.",
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Registration input field
          TextField(
            controller: _busController,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: "e.g. KA06F8558",
              hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.pin_outlined, size: 18, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CityRideTheme.primaryGreen, width: 1.5),
              ),
            ),
          ),

          if (widget.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action button: [ VERIFY BUS ]
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () => widget.onVerify(_busController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: CityRideTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "VERIFY BUS",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
