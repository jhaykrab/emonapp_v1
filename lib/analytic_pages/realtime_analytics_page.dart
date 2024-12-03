import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Emon/widgets/display_energy_container.dart';

class RealTimeAnalyticsPage extends StatefulWidget {
  final double totalEnergy; // Accept energy value from parent

  const RealTimeAnalyticsPage({Key? key, required this.totalEnergy})
      : super(key: key);

  @override
  _RealTimeAnalyticsPageState createState() => _RealTimeAnalyticsPageState();
}

class _RealTimeAnalyticsPageState extends State<RealTimeAnalyticsPage> {
  List<FlSpot> _graphData = [];
  double _maxY = 3.0; // Maximum Y value for the graph

  @override
  void didUpdateWidget(covariant RealTimeAnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update graph data when totalEnergy changes
    if (widget.totalEnergy != oldWidget.totalEnergy) {
      _updateGraphData(widget.totalEnergy);
    }
  }

  void _updateGraphData(double totalEnergy) {
    final now = DateTime.now();
    setState(() {
      _graphData.add(
        FlSpot(now.hour + now.minute / 60.0, totalEnergy),
      );

      // Adjust maxY dynamically
      _maxY = max(_maxY, totalEnergy * 1.1);

      // Remove data older than 24 hours
      _graphData = _graphData.where((spot) {
        final timestamp = DateTime(
          now.year,
          now.month,
          now.day,
          spot.x.toInt(),
          ((spot.x - spot.x.toInt()) * 60).toInt(),
        );
        return now.difference(timestamp).inHours <= 24;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const DisplayEnergyContainer(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
