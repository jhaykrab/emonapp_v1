import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DailyAnalyticsPage extends StatefulWidget {
  final String userId;

  const DailyAnalyticsPage({Key? key, required this.userId}) : super(key: key);

  @override
  _DailyAnalyticsPageState createState() => _DailyAnalyticsPageState();
}

class _DailyAnalyticsPageState extends State<DailyAnalyticsPage> {
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  List<FlSpot> _graphData = [];
  double _maxY =
      10.0; // Dynamic max Y value for graph, can adjust based on data
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeGraphData();

    // Periodically update the graph with new data every minute (simulate new data)
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _addDataPoint();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // Initialize graph data for the current day (daily data points)
  void _initializeGraphData() {
    DateTime now = DateTime.now();
    DateTime startTime = DateTime(now.year, now.month, now.day, 0, 0);

    List<FlSpot> initialData = [];
    for (int i = 0; i < 7; i++) {
      initialData.add(FlSpot(i.toDouble(), 0.0)); // Initialize with 0 energy
    }

    setState(() {
      _graphData = initialData;
      _isLoading = false;
    });
  }

  // Add a new data point (for energy) every minute, keep the data for the last 7 days
  void _addDataPoint() {
    DateTime now = DateTime.now();
    // For simulation, we're incrementing energy by a fixed value
    final newEnergy = _totalEnergy + (0.1 + (now.second / 60));

    final newSpot = FlSpot(
      now.weekday.toDouble() - 1, // Using weekday for x-axis (0-6)
      newEnergy,
    );

    setState(() {
      _totalEnergy = newEnergy; // Update the total energy

      // Add the new spot to the graph data and limit to last 7 days
      _graphData.add(newSpot);

      // Keep only the last 7 data points
      _graphData = _graphData.where((spot) {
        final timeDifference = now.difference(
            DateTime(now.year, now.month, now.day, 0, 0)
                .add(Duration(days: spot.x.toInt())));
        return timeDifference.inDays <= 7;
      }).toList();
    });
  }

  // Callback to handle energy updates (e.g., fetch from Firebase or other source)
  void _onEnergyUpdate(double updatedEnergy) {
    setState(() {
      _totalEnergy = updatedEnergy;
    });
  }

  // Get the formatted current date-time
  String _getFormattedDateTime() {
    DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd-EEEE_HH:mm:ss a').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(255, 54, 83, 56),
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.show_chart,
                              color: Color.fromARGB(255, 231, 175, 22)),
                          SizedBox(width: 8),
                          Text(
                            "Daily Analytics",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color.fromARGB(255, 54, 83, 56),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getFormattedDateTime(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 54, 83, 56),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildBarGraph(),
                  ],
                ),
    );
  }

  Widget _buildBarGraph() {
    return Container(
      height: 400, // Increased the height of the graph card
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            _graphData.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: _graphData[index].y,
                  color: const Color.fromARGB(255, 145, 235, 123),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1.0,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final dayOfWeek =
                      (value.toInt()) % 7; // Map 0-6 to Monday-Sunday
                  const days = [
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                    'Sunday'
                  ];
                  return RotatedBox(
                    quarterTurns: 1, // Slant the text by 45 degrees
                    child: Text(
                      days[dayOfWeek],
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 1.0,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 0.8,
            ),
            // Draw vertical grid lines only for positions 0-6 (representing the days of the week)
            drawVerticalLine: true,
            getDrawingVerticalLine: (value) {
              if (value.toInt() < 7) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 0.8,
                );
              }
              return FlLine(
                color: Colors.transparent, // Hide lines after the 7th day
                strokeWidth: 0,
              );
            },
          ),
          maxY: _maxY,
        ),
      ),
    );
  }
}
