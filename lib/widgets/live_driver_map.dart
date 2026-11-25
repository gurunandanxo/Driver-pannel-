import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/trip_models.dart';

class LiveDriverMap extends StatefulWidget {
  final List<TransitStop> stops;
  final double currentLat;
  final double currentLon;
  final double headingDegrees;
  final int currentStopIndex;
  final bool isDark;

  const LiveDriverMap({
    super.key,
    required this.stops,
    required this.currentLat,
    required this.currentLon,
    required this.headingDegrees,
    required this.currentStopIndex,
    this.isDark = false,
  });

  @override
  State<LiveDriverMap> createState() => _LiveDriverMapState();
}

class _LiveDriverMapState extends State<LiveDriverMap> {
  double _zoomLevel = 1.0;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (widget.stops.isEmpty || _hasError) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 34,
                color: widget.isDark ? Colors.white60 : CityRideTheme.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                "LIVE TRANSIT ROUTE",
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? Colors.white : CityRideTheme.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Map temporarily unavailable.",
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: widget.isDark ? const Color(0xFF94A3B8) : CityRideTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 32,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    "Retry",
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: CityRideTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isDark ? CityRideTheme.cockpitBorder : CityRideTheme.dividerColor,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Custom Painted Route Map Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _DriverMapPainter(
                  stops: widget.stops,
                  busLat: widget.currentLat,
                  busLon: widget.currentLon,
                  headingDegrees: widget.headingDegrees,
                  currentStopIndex: widget.currentStopIndex,
                  zoom: _zoomLevel,
                  isDark: widget.isDark,
                ),
              ),
            ),

            // Top Map Overlay: Active Corridor Pill
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? CityRideTheme.cockpitCardBg.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      size: 13,
                      color: CityRideTheme.primaryGreen,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "LIVE TRANSIT ROUTE",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : CityRideTheme.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Right: Zoom Controls
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildZoomBtn(Icons.add, () {
                    setState(() {
                      _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 2.0);
                    });
                  }),
                  const SizedBox(height: 6),
                  _buildZoomBtn(Icons.remove, () {
                    setState(() {
                      _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 2.0);
                    });
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: widget.isDark ? CityRideTheme.cockpitCardBg : Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: widget.isDark ? Colors.white : CityRideTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _DriverMapPainter extends CustomPainter {
  final List<TransitStop> stops;
  final double busLat;
  final double busLon;
  final double headingDegrees;
  final int currentStopIndex;
  final double zoom;
  final bool isDark;

  _DriverMapPainter({
    required this.stops,
    required this.busLat,
    required this.busLon,
    required this.headingDegrees,
    required this.currentStopIndex,
    required this.zoom,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stops.isEmpty) return;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0A111E) : const Color(0xFFF1F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw Subtle Grid lines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFCBD5E1).withOpacity(0.4)
      ..strokeWidth = 1.0;

    const step = 35.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Determine bounding box
    double minLat = stops.first.latitude;
    double maxLat = stops.first.latitude;
    double minLon = stops.first.longitude;
    double maxLon = stops.first.longitude;

    for (final s in stops) {
      if (s.latitude < minLat) minLat = s.latitude;
      if (s.latitude > maxLat) maxLat = s.latitude;
      if (s.longitude < minLon) minLon = s.longitude;
      if (s.longitude > maxLon) maxLon = s.longitude;
    }

    if (busLat < minLat) minLat = busLat;
    if (busLat > maxLat) maxLat = busLat;
    if (busLon < minLon) minLon = busLon;
    if (busLon > maxLon) maxLon = busLon;

    final latPadding = (maxLat - minLat) * 0.25;
    final lonPadding = (maxLon - minLon) * 0.25;
    minLat -= latPadding;
    maxLat += latPadding;
    minLon -= lonPadding;
    maxLon += lonPadding;

    Offset mapCoord(double lat, double lon) {
      final normX = (maxLon - minLon) == 0 ? 0.5 : (lon - minLon) / (maxLon - minLon);
      final normY = (maxLat - minLat) == 0 ? 0.5 : 1.0 - ((lat - minLat) / (maxLat - minLat));

      final centerX = size.width / 2;
      final centerY = size.height / 2;

      final rawX = normX * (size.width - 60) + 30;
      final rawY = normY * (size.height - 60) + 30;

      final scaledX = centerX + (rawX - centerX) * zoom;
      final scaledY = centerY + (rawY - centerY) * zoom;

      return Offset(scaledX, scaledY);
    }

    // 1. Draw Route Corridor Polyline
    final casingPath = Path();
    final polyPath = Path();

    for (int i = 0; i < stops.length; i++) {
      final pt = mapCoord(stops[i].latitude, stops[i].longitude);
      if (i == 0) {
        casingPath.moveTo(pt.dx, pt.dy);
        polyPath.moveTo(pt.dx, pt.dy);
      } else {
        casingPath.lineTo(pt.dx, pt.dy);
        polyPath.lineTo(pt.dx, pt.dy);
      }
    }

    final casingPaint = Paint()
      ..color = isDark ? const Color(0xFF047857).withOpacity(0.3) : const Color(0xFFBBF7D0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final polyPaint = Paint()
      ..color = CityRideTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(casingPath, casingPaint);
    canvas.drawPath(polyPath, polyPaint);

    // 2. Draw Stop Markers & Geofences
    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final pt = mapCoord(stop.latitude, stop.longitude);
      final isCurrent = i == currentStopIndex;
      final isPassed = i < currentStopIndex;

      // Geofence Ring
      final geofencePaint = Paint()
        ..color = isCurrent
            ? CityRideTheme.accentGreen.withOpacity(0.25)
            : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, 20.0 * zoom, geofencePaint);

      final geofenceBorder = Paint()
        ..color = isCurrent
            ? CityRideTheme.accentGreen.withOpacity(0.6)
            : (isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(pt, 20.0 * zoom, geofenceBorder);

      // Stop Center Dot
      final dotPaint = Paint()
        ..color = isPassed
            ? CityRideTheme.accentGreen
            : (isCurrent ? CityRideTheme.primaryGreen : (isDark ? const Color(0xFF334155) : Colors.white));
      canvas.drawCircle(pt, 6.0, dotPaint);

      final dotBorder = Paint()
        ..color = isCurrent ? Colors.white : (isDark ? Colors.black : const Color(0xFF64748B))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(pt, 6.0, dotBorder);
    }

    // 3. Draw Moving Bus Marker & Heading Arrow
    final busPt = mapCoord(busLat, busLon);

    final pulsePaint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(busPt, 16.0, pulsePaint);

    final busCirclePaint = Paint()..color = CityRideTheme.primaryGreen;
    canvas.drawCircle(busPt, 11.0, busCirclePaint);

    final busBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(busPt, 11.0, busBorderPaint);

    // Direction Heading Pointer
    final headingRad = (headingDegrees - 90.0) * math.pi / 180.0;
    final tipX = busPt.dx + 16.0 * math.cos(headingRad);
    final tipY = busPt.dy + 16.0 * math.sin(headingRad);

    final pointerPaint = Paint()
      ..color = const Color(0xFFFFB020)
      ..style = PaintingStyle.fill;

    final pointerPath = Path();
    pointerPath.moveTo(tipX, tipY);
    pointerPath.lineTo(
      busPt.dx + 7.0 * math.cos(headingRad + 2.5),
      busPt.dy + 7.0 * math.sin(headingRad + 2.5),
    );
    pointerPath.lineTo(
      busPt.dx + 7.0 * math.cos(headingRad - 2.5),
      busPt.dy + 7.0 * math.sin(headingRad - 2.5),
    );
    pointerPath.close();
    canvas.drawPath(pointerPath, pointerPaint);
  }

  @override
  bool shouldRepaint(covariant _DriverMapPainter oldDelegate) {
    return oldDelegate.busLat != busLat ||
        oldDelegate.busLon != busLon ||
        oldDelegate.headingDegrees != headingDegrees ||
        oldDelegate.currentStopIndex != currentStopIndex ||
        oldDelegate.zoom != zoom ||
        oldDelegate.isDark != isDark;
  }
}
