import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Emon/widgets/gauge_widget.dart'; // Import GaugeWidget
import 'package:intl/intl.dart';

class DisplayEnergyContainer extends StatefulWidget {
  const DisplayEnergyContainer({Key? key}) : super(key: key);

  @override
  _DisplayEnergyContainerState createState() => _DisplayEnergyContainerState();
}

class _DisplayEnergyContainerState extends State<DisplayEnergyContainer> {
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  List<FlSpot> _graphData = [];
  double _maxY = 7.0; // Fixed max Y value for the graph
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeGraphData();

    // Periodically update the graph with new data
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _addDataPoint();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeGraphData() {
    DateTime now = DateTime.now();
    DateTime startTime = DateTime(now.year, now.month, now.day, 0, 0);

    List<FlSpot> initialData = [];
    while (startTime.isBefore(now) || startTime.isAtSameMomentAs(now)) {
      initialData.add(FlSpot(
        startTime.hour + startTime.minute / 60.0,
        0.0, // Initialize with 0 energy or fetch actual data if available
      ));
      startTime = startTime.add(const Duration(minutes: 1));
    }

    setState(() {
      _graphData = initialData;
      _isLoading = false;
    });
  }

  void _addDataPoint() {
    DateTime now = DateTime.now();

    // Add a new point with the current energy
    final newSpot = FlSpot(
      now.hour + now.minute / 60.0, // Time in hours
      _totalEnergy,
    );

    setState(() {
      _graphData.add(newSpot);

      // Keep only the last 24 hours of data
      _graphData = _graphData.where((spot) {
        final spotTime = DateTime(
          now.year,
          now.month,
          now.day,
          spot.x.toInt(),
          ((spot.x - spot.x.toInt()) * 60).toInt(),
        );
        final timeDifference = now.difference(spotTime);
        return timeDifference.inHours <= 24;
      }).toList();
    });
  }

  // Callback to handle energy updates from the GaugeWidget
  void _onEnergyUpdate(double updatedEnergy) {
    setState(() {
      _totalEnergy = updatedEnergy;
    });
  }

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
                          Icon(Icons.bolt,
                              color: Color.fromARGB(255, 231, 175, 22)),
                          SizedBox(width: 8),
                          Text(
                            "Realtime Analytics",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pass the onEnergyUpdate callback to the GaugeWidget
                    GaugeWidget(
                      energy: _totalEnergy,
                      onEnergyUpdate: _onEnergyUpdate,
                    ),
                    const SizedBox(height: 20),
                    // Display the current date and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time, // Clock icon
                          color: Color.fromARGB(255, 54, 83, 56), // Icon color
                          size: 18, // Icon size
                        ),
                        const SizedBox(width: 8), // Space between icon and text
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
                    // Display the line chart (gra
                    _buildLineGraph(), // Include the line graph
                  ],
                ),
    );
  }

  Widget _buildLineGraph() {
    return Container(
      height: 350,
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
      child: LineChart(LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _graphData,
            isCurved: true,
            barWidth:
                1.0, // Thinner green line (adjust this value to make it thinner or thicker)
            dotData: FlDotData(
              show: true, // Show dots on each data point
            ),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 54, 83, 56),
                Color.fromARGB(255, 145, 235, 123)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 54, 83, 56).withOpacity(0.3),
                  const Color.fromARGB(255, 145, 235, 123).withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: 0.0,
        maxX: 24.0,
        minY: 0.0,
        maxY: _maxY,
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              "Energy (kWh)",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 0.5,
              getTitlesWidget: (value, _) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              "Time (Hours)",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}:00',
                style: const TextStyle(fontSize: 8),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 0.5,
          verticalInterval: 2,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 0.8,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 0.8,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipMargin: 8,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipRoundedRadius: 8,
            tooltipBorder: const BorderSide(
              color: Colors.white, // Tooltip border color
            ),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                // Convert the time to DateTime object based on the x value (hours)
                DateTime time = DateTime(2024, 1, 1, spot.x.toInt(),
                    ((spot.x - spot.x.toInt()) * 60).toInt());
                String formattedTime = DateFormat('hh:mm a')
                    .format(time); // Format time as '11:01 AM'

                return LineTooltipItem(
                  'Time: $formattedTime\nEnergy: ${spot.y.toStringAsFixed(2)} kWh',
                  TextStyle(
                    color: Color.fromARGB(
                        255, 54, 83, 56), // Dark green text color
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
            // Modify the tooltip background color to white
            getTooltipColor: (touchedSpot) {
              return Colors.white;
            },
          ),
        ),
      )),
    );
  }
}
