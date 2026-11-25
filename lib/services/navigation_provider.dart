import 'package:flutter/material.dart';
import '../models/trip_models.dart';

/// Navigation and Map Abstraction Interface
abstract class NavigationProvider {
  /// Initialize navigation provider with stops
  void initialize(List<TransitStop> stops);

  /// Update vehicle position and heading
  void updatePosition(double latitude, double longitude, double headingDegrees);

  /// Build map widget
  Widget buildMapWidget({
    required BuildContext context,
    required List<TransitStop> stops,
    required double busLatitude,
    required double busLongitude,
    required double headingDegrees,
    required int currentStopIndex,
    bool isDark = false,
  });

  /// Dispose resources
  void dispose();
}
