import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Emon/widgets/gauge_widget.dart'; // Import GaugeWidget

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
    _fetchEnergyData();

    // Periodically update the graph with new data
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _addDataPoint();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEnergyData() async {
    try {
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate a network delay
      double fetchedEnergy = 3.5; // Example fetched energy value

      if (mounted) {
        setState(() {
          _totalEnergy = fetchedEnergy;
          _isLoading = false;
        });
        _addDataPoint(); // Add the first data point
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to fetch energy data. Please try again.";
        });
      }
    }
  }

  void _addDataPoint() {
    final now = DateTime.now();
    final newSpot = FlSpot(
      now.hour + now.minute / 60.0, // Time in hours
      _totalEnergy,
    );

    setState(() {
      _graphData.add(newSpot);

      // Keep only the last 24 hours of data
      _graphData = _graphData.where((spot) {
        final timeDifference = now.difference(DateTime(
          now.year,
          now.month,
          now.day,
          spot.x.toInt(),
          ((spot.x - spot.x.toInt()) * 60).toInt(),
        ));
        return timeDifference.inHours <= 24;
      }).toList();
    });
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
                    const Text(
                      "Current Energy Consumption",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GaugeWidget(energy: _totalEnergy), // Pass total energy here
                    const SizedBox(height: 16),
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
            barWidth: 2.5,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.lightBlueAccent.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minX: 0,
        maxX: 24,
        minY: 0,
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
      )),
    );
  }
}
