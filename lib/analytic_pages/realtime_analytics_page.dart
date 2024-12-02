import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Emon/widgets/display_energy_container.dart';

class RealTimeAnalyticsPage extends StatefulWidget {
  const RealTimeAnalyticsPage({Key? key}) : super(key: key);

  @override
  _RealTimeAnalyticsPageState createState() => _RealTimeAnalyticsPageState();
}

class _RealTimeAnalyticsPageState extends State<RealTimeAnalyticsPage> {
  final DatabaseReference _realtimeRef =
      FirebaseDatabase.instance.ref(); // Root reference for Firebase database
  double _totalEnergy = 0.0;
  List<FlSpot> _graphData = [];
  double _maxY = 3.0; // Maximum Y value for the graph
  late StreamSubscription<DatabaseEvent> _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _listenToRealtimeData(); // Start listening to realtime updates
  }

  @override
  void dispose() {
    _realtimeSubscription.cancel(); // Cancel the subscription when disposed
    super.dispose();
  }

  void _listenToRealtimeData() {
    _realtimeSubscription =
        _realtimeRef.child('SensorReadings').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        double aggregatedEnergy = 0.0;

        data.forEach((key, deviceData) {
          if (deviceData is Map<dynamic, dynamic>) {
            aggregatedEnergy += (deviceData['energy_kWh'] ?? 0.0).toDouble();
          }
        });

        final now = DateTime.now();

        setState(() {
          _totalEnergy = aggregatedEnergy;
          _graphData.add(FlSpot(
            now.hour + now.minute / 60.0,
            _totalEnergy,
          ));
          _maxY = max(_maxY, _totalEnergy * 1.1);

          // Filter out data older than 24 hours
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
            const SizedBox(height: 10),
            const DisplayEnergyContainer(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
