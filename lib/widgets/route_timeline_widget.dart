import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/trip_models.dart';

class RouteTimelineWidget extends StatelessWidget {
  final List<TransitStop> stops;
  final int currentStopIndex;
  final bool isDark;
  final DateTime? tripStartTime;
  final int delayMinutes;
  final int etaToNextStopSeconds;

  const RouteTimelineWidget({
    super.key,
    required this.stops,
    required this.currentStopIndex,
    this.isDark = false,
    this.tripStartTime,
    this.delayMinutes = 0,
    this.etaToNextStopSeconds = 180,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateElapsedMinutes(int upToIndex) {
    int sum = 0;
    for (int i = 0; i < upToIndex && i < stops.length; i++) {
      final est = stops[i].estimatedDurationMinutes;
      sum += est > 0 ? est : 4;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            "No stops loaded for this route",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
            ),
          ),
        ),
      );
    }

    // Base start time: Align so that currentStop arrival time roughly matches now
    final elapsedMinutes = _calculateElapsedMinutes(currentStopIndex);
    final baseStartTime = tripStartTime ??
        DateTime.now().subtract(Duration(minutes: elapsedMinutes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column Sub-Headers
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 2, right: 2),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  "ARR / ETA",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF64748B) : CityRideTheme.textLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "STOPS & SEQUENCE",
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF64748B) : CityRideTheme.textLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 48,
                child: Text(
                  "DEPART",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF64748B) : CityRideTheme.textLight,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Vertical Bus-Trip Timeline
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stops.length,
          itemBuilder: (context, index) {
            final stop = stops[index];
            final isPassed = index < currentStopIndex;
            final isCurrent = index == currentStopIndex;
            final isNext = index == currentStopIndex + 1;
            final isLast = index == stops.length - 1;

            // Cumulative arrival & departure calculations
            final cumMinutes = _calculateElapsedMinutes(index);
            final stopArrival = baseStartTime.add(Duration(minutes: cumMinutes));
            final stopDeparture = stopArrival.add(const Duration(minutes: 2));
            final etaTime = stopArrival.add(Duration(minutes: delayMinutes));

            final arrivalStr = _formatTime(stopArrival);
            final departureStr = _formatTime(stopDeparture);
            final etaStr = _formatTime(etaTime);

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 2),
              padding: EdgeInsets.symmetric(
                horizontal: isCurrent ? 6 : 2,
                vertical: isCurrent ? 6 : 2,
              ),
              decoration: isCurrent
                  ? BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B).withOpacity(0.3)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? CityRideTheme.accentGreen.withOpacity(0.4)
                            : const Color(0xFFA7F3D0),
                        width: 1.2,
                      ),
                    )
                  : null,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. LEFT SIDE: Scheduled Arrival & ETA
                    SizedBox(
                      width: 64,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            arrivalStr,
                            style: GoogleFonts.inter(
                              fontSize: isCurrent ? 13 : 12.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : (isPassed ? FontWeight.w600 : FontWeight.w700),
                              color: isPassed
                                  ? (isDark ? const Color(0xFF64748B) : CityRideTheme.textLight)
                                  : (isCurrent
                                      ? (isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen)
                                      : (isDark ? Colors.white : CityRideTheme.textDark)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPassed ? "ARRIVED" : "ETA: $etaStr",
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: isCurrent || isNext ? FontWeight.w700 : FontWeight.w500,
                              color: isPassed
                                  ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                                  : (isCurrent
                                      ? (isDark ? CityRideTheme.accentGreen : const Color(0xFF059669))
                                      : (isNext
                                          ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                                          : (isDark ? const Color(0xFF64748B) : CityRideTheme.textLight))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. CENTER: Timeline Marker & Connecting Line
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          // Timeline Circular Dot Marker
                          _buildTimelineMarker(index, isPassed, isCurrent, isNext, isLast),
                          // Connecting Line to next stop
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2.5,
                                color: isPassed
                                    ? CityRideTheme.accentGreen
                                    : (isDark ? CityRideTheme.cockpitBorder : const Color(0xFFE2E8F0)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. CENTER: Stop Name, Kannada Name & Status Info
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 4.0 : 14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: isCurrent ? 13 : 12,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : (isPassed ? FontWeight.w600 : FontWeight.w700),
                                color: isPassed
                                    ? (isDark ? const Color(0xFF64748B) : CityRideTheme.textMuted)
                                    : (isDark ? Colors.white : CityRideTheme.textDark),
                                letterSpacing: 0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (stop.kannadaName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                stop.kannadaName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isPassed
                                      ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                                      : (isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            // Status Badge / Label
                            _buildStatusInfo(index, isPassed, isCurrent, isNext, isLast),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 4. RIGHT SIDE: Scheduled Departure & Clock Icon
                    SizedBox(
                      width: 48,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isLast ? "-" : departureStr,
                            style: GoogleFonts.inter(
                              fontSize: isCurrent ? 13 : 12,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : (isPassed ? FontWeight.w600 : FontWeight.w700),
                              color: isPassed
                                  ? (isDark ? const Color(0xFF64748B) : CityRideTheme.textLight)
                                  : (isDark ? Colors.white : CityRideTheme.textDark),
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isLast)
                            Text(
                              "-",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF64748B) : CityRideTheme.textLight,
                              ),
                            )
                          else
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: isPassed
                                  ? (isDark ? const Color(0xFF64748B) : CityRideTheme.textLight)
                                  : (isCurrent
                                      ? (isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen)
                                      : (isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineMarker(
    int index,
    bool isPassed,
    bool isCurrent,
    bool isNext,
    bool isLast,
  ) {
    if (isCurrent) {
      // Large highlighted circular marker with live pulse shadow
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isDark ? CityRideTheme.cockpitCardBg : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen).withOpacity(0.45),
              blurRadius: 6,
              spreadRadius: 1.5,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isDark ? CityRideTheme.accentGreen : CityRideTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    if (isPassed) {
      // Completed stop: Green checkmark marker
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: CityRideTheme.accentGreen,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
        ),
      );
    }

    if (isNext) {
      // Next stop: Highlighted blue marker
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    // Upcoming stop: Light gray circular marker
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusInfo(
    int index,
    bool isPassed,
    bool isCurrent,
    bool isNext,
    bool isLast,
  ) {
    if (isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isDark ? CityRideTheme.accentGreen : const Color(0xFF34D399),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus_rounded,
              size: 11,
              color: CityRideTheme.accentGreen,
            ),
            const SizedBox(width: 4),
            Text(
              "BUS HERE (LIVE)",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF065F46),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    if (isNext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.near_me_rounded,
              size: 10,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 3),
            Text(
              "NEXT STOP",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    if (isPassed) {
      return Text(
        "Completed",
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF64748B) : CityRideTheme.textLight,
        ),
      );
    }

    final stop = stops[index];
    final isTurnaround = !isLast &&
        !stop.isReturnStop &&
        ((index + 1 < stops.length && stops[index + 1].isReturnStop) ||
            index == (stops.length / 2).floor());

    if (isLast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "FINAL STOP",
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    if (isTurnaround) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "OUTBOUND TURNAROUND",
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    if (stop.isReturnStop) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3B1E54) : const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          "RETURN",
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE),
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    return Text(
      "Approximation",
      style: GoogleFonts.inter(
        fontSize: 10,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: isDark ? const Color(0xFF64748B) : CityRideTheme.textLight,
      ),
    );
  }
}
