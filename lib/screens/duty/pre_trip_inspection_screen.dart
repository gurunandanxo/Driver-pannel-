import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../services/trip_engine.dart';

class PreTripInspectionScreen extends StatefulWidget {
  const PreTripInspectionScreen({super.key});

  @override
  State<PreTripInspectionScreen> createState() => _PreTripInspectionScreenState();
}

class _PreTripInspectionScreenState extends State<PreTripInspectionScreen> {
  final _tripEngine = TripEngine();
  final _imagePicker = ImagePicker();

  bool? _brakes;
  bool? _tyres;
  bool? _lights;
  bool? _doors;
  bool? _horn;
  bool? _mirrors;
  bool? _firstAid;
  bool? _fuel;
  bool? _air;

  // 8th Item: Other Issue
  bool _otherIssueSelected = false;
  String _otherProblemType = 'Other';
  final TextEditingController _otherDescController = TextEditingController();
  String? _otherPhotoPath;

  bool _isSubmitting = false;

  final List<String> _problemCategories = [
    'Engine problem',
    'Electrical problem',
    'Windshield / Wipers',
    'Door mechanism problem',
    'Suspension problem',
    'Interior / Seats problem',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final insp = _tripEngine.inspection;
    _brakes = insp.brakesOk;
    _tyres = insp.tyresOk;
    _lights = insp.lightsOk;
    _doors = insp.doorsOk;
    _horn = insp.hornOk;
    _mirrors = insp.mirrorsOk;
    _firstAid = insp.firstAidOk;
    _fuel = insp.fuelOk;
    _air = insp.airOk;
    _otherIssueSelected = insp.otherIssuePresent;
    if (insp.otherIssueDescription != null) {
      _otherDescController.text = insp.otherIssueDescription!;
    }
    _otherPhotoPath = insp.otherIssueLocalPhotoPath;
  }

  @override
  void dispose() {
    _otherDescController.dispose();
    super.dispose();
  }

  bool get _isAllStandardReviewed =>
      _brakes != null &&
      _tyres != null &&
      _lights != null &&
      _doors != null &&
      _horn != null &&
      _mirrors != null &&
      _firstAid != null;

  bool get _hasStandardProblem =>
      _brakes == false ||
      _tyres == false ||
      _lights == false ||
      _doors == false ||
      _horn == false ||
      _mirrors == false ||
      _firstAid == false;

  bool get _hasAnyIssue => _hasStandardProblem || _otherIssueSelected;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (file != null) {
        setState(() {
          _otherPhotoPath = file.path;
        });
      }
    } catch (e) {
      debugPrint('[Inspection] Image pick error: $e');
    }
  }

  void _markAllPassed() {
    setState(() {
      _brakes = true;
      _tyres = true;
      _lights = true;
      _doors = true;
      _horn = true;
      _mirrors = true;
      _firstAid = true;
      _fuel = true;
      _air = true;
      _otherIssueSelected = false;
      _otherPhotoPath = null;
      _otherDescController.clear();
    });
  }

  Future<void> _handleSubmitInspection() async {
    if (!_isAllStandardReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please review and mark all 7 standard safety checks.'),
          backgroundColor: CityRideTheme.warningColor,
        ),
      );
      return;
    }

    if (_otherIssueSelected && _otherDescController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description for the reported Other Issue.'),
          backgroundColor: CityRideTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    _tripEngine.setInspectionCheck(
      brakes: _brakes,
      tyres: _tyres,
      lights: _lights,
      doors: _doors,
      horn: _horn,
      mirrors: _mirrors,
      firstAid: _firstAid,
      fuel: _fuel ?? true,
      air: _air ?? true,
      otherIssuePresent: _otherIssueSelected,
      otherIssueDescription: _otherIssueSelected ? _otherDescController.text.trim() : null,
      otherIssueLocalPhotoPath: _otherIssueSelected ? _otherPhotoPath : null,
    );

    if (_hasAnyIssue) {
      // Record issue in database
      await _tripEngine.submitInspectionWithIssue(
        problemType: _otherIssueSelected ? _otherProblemType : 'Safety Inspection Defect',
        description: _otherIssueSelected
            ? _otherDescController.text.trim()
            : 'Standard safety audit flagged problems in vehicle checks.',
        localPhotoPath: _otherPhotoPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '⚠ VEHICLE DEFECT RECORDED & SUBMITTED TO DEPOT MAINTENANCE',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: CityRideTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(milliseconds: 3500),
        ),
      );
    } else {
      _tripEngine.passAllInspection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pre-Trip Safety Audit Completed',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      '5/5 vehicle checks passed • Ready for route',
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
          ),
          duration: const Duration(milliseconds: 3500),
        ),
      );
    }

    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bus = _tripEngine.verifiedBus;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Pre-Trip Safety Inspection",
          style: GoogleFonts.inter(fontSize: 17.5, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
        ),
        actions: [
          TextButton.icon(
            onPressed: _markAllPassed,
            icon: const Icon(Icons.done_all_rounded, size: 18, color: CityRideTheme.primaryGreen),
            label: Text(
              "ALL OK",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CityRideTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Info Banner with overflow prevention
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CityRideTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bus?.busNumber ?? "KA06F8558",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${bus?.model ?? 'Tata Starbus Ultra EV'} • ${bus?.depotName ?? 'Tumakuru Depot #1'}",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section Heading
                    Text(
                      "7-POINT MANDATORY SAFETY AUDIT",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: CityRideTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 1. Braking System
                    _buildInspectionItemCard(
                      title: "1. 🛑 Service & Parking Brakes",
                      status: _brakes,
                      onSelect: (ok) => setState(() => _brakes = ok),
                    ),

                    // 2. Tyres & Wheel Nuts
                    _buildInspectionItemCard(
                      title: "2. ◉ Tyres & Wheel Security",
                      status: _tyres,
                      onSelect: (ok) => setState(() => _tyres = ok),
                    ),

                    // 3. Lights & Indicators
                    _buildInspectionItemCard(
                      title: "3. 💡 Headlights & Indicators",
                      status: _lights,
                      onSelect: (ok) => setState(() => _lights = ok),
                    ),

                    // 4. Doors & Mechanism
                    _buildInspectionItemCard(
                      title: "4. 🚪 Passenger & Emergency Doors",
                      status: _doors,
                      onSelect: (ok) => setState(() => _doors = ok),
                    ),

                    // 5. Horn
                    _buildInspectionItemCard(
                      title: "5. 📢 Horn & Reverse Warning",
                      status: _horn,
                      onSelect: (ok) => setState(() => _horn = ok),
                    ),

                    // 6. Mirrors
                    _buildInspectionItemCard(
                      title: "6. 🪞 Rearview & Blindspot Mirrors",
                      status: _mirrors,
                      onSelect: (ok) => setState(() => _mirrors = ok),
                    ),

                    // 7. First Aid Kit
                    _buildInspectionItemCard(
                      title: "7. 🩹 First Aid & Emergency Kit",
                      status: _firstAid,
                      onSelect: (ok) => setState(() => _firstAid = ok),
                    ),

                    const SizedBox(height: 8),

                    // 6. ITEM: OTHER ISSUE MODULE
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _otherIssueSelected ? CityRideTheme.defectWarningBg : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _otherIssueSelected ? CityRideTheme.defectWarningBorder : CityRideTheme.dividerColor,
                          width: _otherIssueSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.build_circle_outlined, size: 20, color: CityRideTheme.safetyAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "6. ⚠ Other Issue Found",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CityRideTheme.textDark,
                                  ),
                                ),
                              ),
                              // Toggle Button: No Other Issue vs Issue Found
                              Switch(
                                value: _otherIssueSelected,
                                activeColor: CityRideTheme.defectWarningText,
                                onChanged: (val) {
                                  setState(() {
                                    _otherIssueSelected = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          Text(
                            "Report any defects not covered in the standard 5 safety items (AC, doors, wiper, seats, etc.)",
                            style: GoogleFonts.inter(fontSize: 11.5, color: CityRideTheme.textMuted),
                          ),

                          if (_otherIssueSelected) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFFECACA), height: 1),
                            const SizedBox(height: 12),

                            Text(
                              "Problem Category",
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CityRideTheme.dividerColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _otherProblemType,
                                  isExpanded: true,
                                  items: _problemCategories.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _otherProblemType = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            Text(
                              "Problem Description",
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _otherDescController,
                              maxLines: 2,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: "Describe the issue or defective part...",
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: CityRideTheme.textLight),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: CityRideTheme.dividerColor),
                                ),
                                contentPadding: const EdgeInsets.all(10),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Photo Attachment
                            Text(
                              "Defect Photo (Optional)",
                              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: CityRideTheme.textDark),
                            ),
                            const SizedBox(height: 6),

                            if (_otherPhotoPath != null)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(_otherPhotoPath!),
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () => setState(() => _otherPhotoPath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 14),
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
                                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                      label: const Text("CAMERA"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                                      label: const Text("GALLERY"),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Submit Button Dock
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: CityRideTheme.dividerColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || !_isAllStandardReviewed) ? null : _handleSubmitInspection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasAnyIssue ? CityRideTheme.warningColor : CityRideTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _hasAnyIssue ? "SUBMIT ISSUE & PROCEED" : "CONFIRM & SUBMIT AUDIT",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionItemCard({
    required String title,
    required bool? status,
    required ValueChanged<bool> onSelect,
  }) {
    final isOk = status == true;
    final isProblem = status == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOk
            ? const Color(0xFFF0FDF4)
            : (isProblem ? CityRideTheme.defectWarningBg : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOk
              ? const Color(0xFF86EFAC)
              : (isProblem
                  ? CityRideTheme.defectWarningBorder
                  : CityRideTheme.dividerColor),
          width: (isOk || isProblem) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: CityRideTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),

          // Segmented Selection Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOk ? CityRideTheme.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOk
                            ? CityRideTheme.primaryGreen
                            : CityRideTheme.dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: isOk ? Colors.white : CityRideTheme.accentGreen,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "✓ OK",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isOk ? Colors.white : CityRideTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isProblem
                          ? CityRideTheme.defectWarningText
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isProblem
                            ? CityRideTheme.defectWarningText
                            : CityRideTheme.dividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 15,
                          color: isProblem
                              ? Colors.white
                              : CityRideTheme.defectWarningText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "⚠ PROBLEM",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isProblem
                                ? Colors.white
                                : CityRideTheme.defectWarningText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
