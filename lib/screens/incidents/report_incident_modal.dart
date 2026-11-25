import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../models/incident_models.dart';
import '../../services/incident_service.dart';
import '../../services/trip_engine.dart';

class ReportIncidentModal extends StatefulWidget {
  final bool isDark;

  const ReportIncidentModal({super.key, this.isDark = false});

  @override
  State<ReportIncidentModal> createState() => _ReportIncidentModalState();
}

class _ReportIncidentModalState extends State<ReportIncidentModal> {
  final _incidentService = IncidentService();
  final _tripEngine = TripEngine();
  final _picker = ImagePicker();

  String _selectedType = DriverIncident.incidentTypes.first;
  final TextEditingController _descController = TextEditingController();
  String? _photoPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      debugPrint('[Incident] Photo pick error: $e');
    }
  }

  Future<void> _handleSubmit() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a brief description of the incident.'),
          backgroundColor: CityRideTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final trip = _tripEngine.activeTrip;
    final incident = await _incidentService.submitIncident(
      incidentType: _selectedType,
      description: desc,
      tripId: trip?.id,
      vehicleId: trip?.bus.busNumber ?? _tripEngine.verifiedBus?.busNumber,
      routeId: trip?.route.id ?? _tripEngine.verifiedRoute?.id,
      localPhotoPath: _photoPath,
    );

    _tripEngine.incrementIncidentCount();

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: CityRideTheme.accentGreen, size: 24),
            const SizedBox(width: 8),
            Text("Incident Logged", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "Incident reference ${incident?.incidentCode ?? 'INC-000'} has been registered with Central OCC and emergency dispatchers.",
          style: GoogleFonts.inter(fontSize: 13.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: CityRideTheme.primaryGreen),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? CityRideTheme.cockpitCardBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: CityRideTheme.warningColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Report Transit Incident",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : CityRideTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Logs an operational event with live telemetry for the Central OCC.",
              style: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textMuted),
            ),
            const SizedBox(height: 16),

            // Incident Type Dropdown
            Text(
              "INCIDENT TYPE",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : CityRideTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: widget.isDark ? CityRideTheme.cockpitCardBg : Colors.white,
                  items: DriverIncident.incidentTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? Colors.white : CityRideTheme.textDark,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              "DESCRIPTION",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: widget.isDark ? Colors.white : CityRideTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText: "State road/vehicle conditions, delay estimate, or obstruction details...",
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textLight),
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF1E293B) : CityRideTheme.scaffoldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CityRideTheme.primaryGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 14),

            // Add Incident Photo
            Text(
              "ATTACH EVIDENCE PHOTO (OPTIONAL)",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CityRideTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            if (_photoPath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photoPath!),
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () => setState(() => _photoPath = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text("CAMERA"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text("GALLERY"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Submit Incident Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        "SUBMIT INCIDENT REPORT",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
