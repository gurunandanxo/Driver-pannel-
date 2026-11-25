import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

enum StepStateStatus {
  locked,
  active,
  completed,
  ready,
}

class StepProgressIndicator extends StatelessWidget {
  final bool isBusVerified;
  final bool isInspectionCompleted;
  final bool isRouteVerified;
  final bool isReadyToStart;
  final bool isTripActive;

  const StepProgressIndicator({
    super.key,
    required this.isBusVerified,
    required this.isInspectionCompleted,
    required this.isRouteVerified,
    required this.isReadyToStart,
    this.isTripActive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine each step's state
    final step1 = isBusVerified ? StepStateStatus.completed : StepStateStatus.active;
    
    final step2 = !isBusVerified
        ? StepStateStatus.locked
        : (isInspectionCompleted ? StepStateStatus.completed : StepStateStatus.active);

    final step3 = !isInspectionCompleted
        ? StepStateStatus.locked
        : (isRouteVerified ? StepStateStatus.completed : StepStateStatus.active);

    final step4 = !isRouteVerified
        ? StepStateStatus.locked
        : (isTripActive ? StepStateStatus.completed : StepStateStatus.ready);

    final currentStepString = isTripActive
        ? "TRIP ACTIVE"
        : (isReadyToStart
            ? "STEP 4/4"
            : (isRouteVerified
                ? "STEP 4/4"
                : (isInspectionCompleted
                    ? "STEP 3/4"
                    : (isBusVerified ? "STEP 2/4" : "STEP 1/4"))));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CityRideTheme.workflowBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: CityRideTheme.workflowAccent.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Distinct Left Color Accent Bar
              Container(
                width: 4.5,
                color: CityRideTheme.workflowAccent,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bold Solid Fill Module Header Area
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: const BoxDecoration(
                        color: CityRideTheme.workflowHeaderBg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sync_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DRIVER WORKFLOW",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    "Sequential step progress",
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isReadyToStart || isTripActive
                                  ? const Color(0xFF10B981)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              currentStepString,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: CityRideTheme.workflowBorder),

                    // Content Area with Steps Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          _buildStepItem(number: "1", title: "VEHICLE", status: step1),
                          _buildConnectingLine(isDone: isBusVerified),
                          _buildStepItem(number: "2", title: "SAFETY", status: step2),
                          _buildConnectingLine(isDone: isInspectionCompleted),
                          _buildStepItem(number: "3", title: "ROUTE", status: step3),
                          _buildConnectingLine(isDone: isRouteVerified),
                          _buildStepItem(number: "4", title: "START", status: step4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingLine({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isDone ? CityRideTheme.accentGreen : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required StepStateStatus status,
  }) {
    Color circleBg;
    Color circleBorder;
    Widget content;

    switch (status) {
      case StepStateStatus.completed:
        circleBg = CityRideTheme.accentGreen;
        circleBorder = CityRideTheme.accentGreen;
        content = const Icon(Icons.check, size: 13, color: Colors.white);
        break;
      case StepStateStatus.active:
        circleBg = CityRideTheme.primaryGreen;
        circleBorder = CityRideTheme.primaryGreen;
        content = Text(
          number,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
        );
        break;
      case StepStateStatus.ready:
        circleBg = const Color(0xFF047857);
        circleBorder = CityRideTheme.accentGreen;
        content = const Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white);
        break;
      case StepStateStatus.locked:
        circleBg = const Color(0xFFF1F5F9);
        circleBorder = const Color(0xFFCBD5E1);
        content = Text(
          number,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: Border.all(color: circleBorder, width: status == StepStateStatus.active ? 2 : 1),
            boxShadow: (status == StepStateStatus.active || status == StepStateStatus.ready)
                ? [
                    BoxShadow(
                      color: CityRideTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(child: content),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: status == StepStateStatus.active || status == StepStateStatus.ready
                ? FontWeight.w800
                : FontWeight.w600,
            color: status == StepStateStatus.active || status == StepStateStatus.ready
                ? CityRideTheme.primaryGreen
                : (status == StepStateStatus.completed ? CityRideTheme.textDark : CityRideTheme.textLight),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
