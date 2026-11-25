import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trip_models.dart';
import '../../services/trip_history_service.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final _historyService = TripHistoryService();

  @override
  void initState() {
    super.initState();
    _historyService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _historyService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showTripDetailsModal(TripSummary summary) {
    final startTimeStr = DateFormat('hh:mm a, dd MMM').format(summary.startTime);
    final endTimeStr = DateFormat('hh:mm a, dd MMM').format(summary.endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Trip Details",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: CityRideTheme.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CityRideTheme.lightGreenChip,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    summary.busNumber,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: CityRideTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "${summary.routeCode} • ${summary.routeName}",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: CityRideTheme.textDark),
            ),
            const SizedBox(height: 16),
            Divider(color: CityRideTheme.dividerColor),
            const SizedBox(height: 12),

            _buildModalRow("Trip ID", summary.tripId),
            _buildModalRow("Route Summary", summary.routeSummary),
            _buildModalRow("Turnaround Stop", summary.outboundDestination),
            _buildModalRow("Started", startTimeStr),
            _buildModalRow("Completed", endTimeStr),
            _buildModalRow("Total Duration", "${summary.duration.inMinutes} min"),
            _buildModalRow("Delay", summary.delayMinutes > 0 ? "+${summary.delayMinutes} min" : "On Time"),
            _buildModalRow("Stops Completed", "${summary.stopsCompleted} of ${summary.totalStops} stops"),
            _buildModalRow("Incidents Logged", "${summary.incidentsCount}"),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CityRideTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("CLOSE DETAILS"),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: CityRideTheme.textMuted)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: CityRideTheme.textDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _historyService.filteredRecords;
    final currentFilter = _historyService.currentFilter;

    return Scaffold(
      backgroundColor: CityRideTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Trip History",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CityRideTheme.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Tabs: TODAY, YESTERDAY, THIS WEEK, THIS MONTH
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: HistoryFilter.values.map((filter) {
                    final isSelected = filter == currentFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _historyService.setFilter(filter),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? CityRideTheme.primaryGreen : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            filter.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : CityRideTheme.textDark,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // History Records List
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "No trips recorded for ${currentFilter.displayName.toLowerCase()}.",
                            style: GoogleFonts.inter(fontSize: 14, color: CityRideTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final item = records[index];
                        final dateStr = DateFormat('dd MMM yyyy').format(item.startTime);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: CityRideTheme.dividerColor),
                          ),
                          child: InkWell(
                            onTap: () => _showTripDetailsModal(item),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: CityRideTheme.lightGreenChip,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.routeCode,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: CityRideTheme.primaryGreen,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            item.busNumber,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: CityRideTheme.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: CityRideTheme.lightGreenChip,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "✓ COMPLETED",
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: CityRideTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Route Summary: Start -> Outbound Destination -> Return
                                  Text(
                                    item.routeSummary,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: CityRideTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${item.duration.inMinutes} min duration • ${item.stopsCompleted} stops completed",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: CityRideTheme.textMuted,
                                        ),
                                      ),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.inter(fontSize: 11, color: CityRideTheme.textLight),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
