import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/inspection_models.dart';

/// Pre-trip Safety Check Module for the CityRide Driver Dashboard.
///
/// Implements dynamic real-time checking:
/// - Connects to real [PreTripInspection] data (0/7 when empty, X/7 as items are toggled).
/// - Shows real status pill:
///   - 0/7: ⚪ Safety Check Required
///   - 1-6/7: 🟡 In Progress (X/7)
///   - 7/7: 🟢 SAFETY VERIFIED
///   - Critical Issue: 🔴 SAFETY ISSUE (trip start blocked)
/// - Thin progress bar reacting directly to completion fraction.
/// - 7 interactive checklist items (Brakes, Tyres, Lights, Doors, Horn, Mirrors, First Aid Kit)
///   with interactive checkboxes that update the count and progress in real time.
/// - Dynamic action button: START SAFETY CHECK / CONTINUE CHECK / VIEW RE-INSPECT / VIEW ISSUE.
class SafetyCheckModule extends StatefulWidget {
  final PreTripInspection inspection;
  final Function(String key, bool passed) onToggleItem;
  final VoidCallback onOpenInspectionScreen;

  const SafetyCheckModule({
    super.key,
    required this.inspection,
    required this.onToggleItem,
    required this.onOpenInspectionScreen,
  });

  @override
  State<SafetyCheckModule> createState() => _SafetyCheckModuleState();
}

class _SafetyCheckModuleState extends State<SafetyCheckModule> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final inspection = widget.inspection;
    final int completedCount = inspection.completedChecksCount;
    final double progress = inspection.progressFraction;
    final bool isPassed = inspection.isFullyCompleted;
    final bool hasIssue = inspection.hasCriticalIssue;
    final bool isStarted = inspection.isStarted;

    // Determine status badge colors and labels
    Color statusBadgeBg;
    Color statusBadgeText;
    Color statusBadgeBorder;
    String statusBadgeLabel;

    if (hasIssue) {
      statusBadgeBg = const Color(0xFFFEE2E2);
      statusBadgeText = const Color(0xFFB91C1C);
      statusBadgeBorder = const Color(0xFFFECACA);
      statusBadgeLabel = "SAFETY ISSUE";
    } else if (isPassed) {
      statusBadgeBg = const Color(0xFFDCFCE7);
      statusBadgeText = const Color(0xFF15803D);
      statusBadgeBorder = const Color(0xFFBBF7D0);
      statusBadgeLabel = "5/5 PASSED ✓";
    } else if (isStarted) {
      statusBadgeBg = const Color(0xFFFEF3C7);
      statusBadgeText = const Color(0xFFB45309);
      statusBadgeBorder = const Color(0xFFFDE68A);
      statusBadgeLabel = "IN PROGRESS ($completedCount/7)";
    } else {
      statusBadgeBg = const Color(0xFFF1F5F9);
      statusBadgeText = const Color(0xFF64748B);
      statusBadgeBorder = const Color(0xFFE2E8F0);
      statusBadgeLabel = "REQUIRED";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
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
          // Header Row: Shield icon + SAFETY CHECK + Status Pill + Expand toggle
          Row(
            children: [
              Icon(
                hasIssue
                    ? Icons.warning_amber_rounded
                    : (isPassed ? Icons.verified_user_rounded : Icons.shield_outlined),
                size: 20,
                color: hasIssue
                    ? const Color(0xFFDC2626)
                    : (isPassed ? const Color(0xFF16A34A) : CityRideTheme.primaryGreen),
              ),
              const SizedBox(width: 8),
              Text(
                "SAFETY CHECK",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusBadgeBorder),
                ),
                child: Text(
                  statusBadgeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusBadgeText,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? "Hide" : "Details",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: CityRideTheme.primaryGreen,
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: CityRideTheme.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Subline: Dynamic X/7 completed or safety issue summary
          Text(
            hasIssue
                ? (inspection.failedItemSummary ?? "Safety issue reported • Trip start blocked")
                : (isPassed
                    ? "7/7 completed • Safety verified"
                    : "$completedCount/7 completed"),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasIssue ? const Color(0xFFDC2626) : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 8),

          // Progress Bar: Dynamic percentage fill matching X / 7
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasIssue
                    ? const Color(0xFFDC2626)
                    : (isPassed ? const Color(0xFF16A34A) : CityRideTheme.primaryGreen),
              ),
            ),
          ),

          // Collapsible Checklist: 7 core safety items with interactive checkboxes
          if (_isExpanded) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildCheckItem(
                    key: 'brakes',
                    label: 'Brakes',
                    isOk: inspection.brakesOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'tyres',
                    label: 'Tyres',
                    isOk: inspection.tyresOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'lights',
                    label: 'Lights',
                    isOk: inspection.lightsOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'doors',
                    label: 'Doors',
                    isOk: inspection.doorsOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'horn',
                    label: 'Horn',
                    isOk: inspection.hornOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'mirrors',
                    label: 'Mirrors',
                    isOk: inspection.mirrorsOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'firstAid',
                    label: 'First Aid Kit',
                    isOk: inspection.firstAidOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'fuel',
                    label: 'Fuel',
                    isOk: inspection.fuelOk,
                  ),
                  _buildDivider(),
                  _buildCheckItem(
                    key: 'air',
                    label: 'Air',
                    isOk: inspection.airOk,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Button: Dynamic button state
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: widget.onOpenInspectionScreen,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: hasIssue ? const Color(0xFFDC2626) : CityRideTheme.primaryGreen,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                hasIssue
                    ? "VIEW ISSUE"
                    : (isPassed
                        ? "VIEW / RE-INSPECT"
                        : (isStarted ? "CONTINUE CHECK" : "START SAFETY CHECK")),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: hasIssue ? const Color(0xFFDC2626) : CityRideTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required String key,
    required String label,
    required bool? isOk,
  }) {
    final bool checked = isOk == true;
    final bool failed = isOk == false;

    return InkWell(
      onTap: () {
        // Toggle item: if checked true -> toggle to false or null; if false/null -> toggle to true
        widget.onToggleItem(key, !checked);
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Interactive Checkbox icon
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked
                    ? const Color(0xFF10B981)
                    : (failed ? const Color(0xFFEF4444) : Colors.white),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked
                      ? const Color(0xFF10B981)
                      : (failed ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : (failed
                      ? const Icon(Icons.close, size: 15, color: Colors.white)
                      : null),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: checked ? const Color(0xFF0F172A) : const Color(0xFF475569),
              ),
            ),
            const Spacer(),
            if (checked)
              Text(
                "PASSED ✓",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              )
            else if (failed)
              Text(
                "FAILED ⚠",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              )
            else
              Text(
                "Pending",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
    );
  }
}
