import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class RealTimeAnalyticsPage extends StatefulWidget {
  const RealTimeAnalyticsPage({Key? key}) : super(key: key);

  @override
  _RealTimeAnalyticsPageState createState() => _RealTimeAnalyticsPageState();
}

class _RealTimeAnalyticsPageState extends State<RealTimeAnalyticsPage> {
  final DatabaseReference _realtimeRef =
      FirebaseDatabase.instance.ref('SensorReadings');
  double _totalEnergy = 0.0;
  List<FlSpot> _graphData = [];
  double _maxY = 3.0; // Initialize maxY; adjust as needed

  @override
  void initState() {
    super.initState();
    _listenToRealtimeData();
  }

  void _listenToRealtimeData() {
    _realtimeRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final energy = (data['energy_kWh'] ?? 0.0).toDouble();
        final now = DateTime.now();
        setState(() {
          _totalEnergy = energy;
          _graphData.add(FlSpot(
            now.hour + now.minute / 60.0,
            energy,
          ));
          _maxY =
              max(_maxY, energy * 1.1); // Dynamically adjust maxY with a buffer

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildGaugeWidget(),
            const SizedBox(height: 20),
            Expanded(
              flex: 2, // Gauge and graph balance
              child: _buildLineGraph(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGaugeWidget() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.10,
      padding: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8, // Slightly reduced blur
            spreadRadius: 1, // Slightly reduced spread
            offset: const Offset(0, 4), // Slightly reduced offset
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize
            .min, // Ensures the card is only as large as its contents
        children: [
          Text(
            "${_totalEnergy.toStringAsFixed(3)} kWh",
            style: const TextStyle(
              fontSize: 24, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          const Text(
            "Current Energy Consumption",
            style: TextStyle(fontSize: 14), // Reduced font size
          ),
        ],
      ),
    );
  }

  Widget _buildLineGraph() {
    final numLabels = 7;
    final interval = _maxY / (numLabels - 1);

    return Container(
      height: MediaQuery.of(context).size.height * 0.2, // 30% of screen height
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced border radius
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8, // Reduced blur
            spreadRadius: 1, // Reduced spread
            offset: const Offset(0, 4), // Reduced offset
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
        maxY: _maxY, // Use the dynamic _maxY
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
              reservedSize: 25, // Slightly increase reserved size for labels
              interval: interval, // Dynamic interval
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1), // Display one decimal place
                  style: const TextStyle(fontSize: 8),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                'Time (Hours)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2.0,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                return Transform.rotate(
                  angle: -pi / 4, // Rotate for better readability
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '$hour:00',
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.end,
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
          horizontalInterval: interval, // Dynamic interval for grid lines
          verticalInterval: 2.0,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 0.8,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.3),
            strokeWidth: 0.8,
          ),
        ),
      )),
    );
  }
}
