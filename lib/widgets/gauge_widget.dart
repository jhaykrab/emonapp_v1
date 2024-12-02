import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GaugeWidget extends StatefulWidget {
  final double energy;
  const GaugeWidget({Key? key, required this.energy}) : super(key: key);

  @override
  _GaugeWidgetState createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget> {
  double _totalDailyEnergy = 0.0;
  bool _isLoading = true;
  late StreamSubscription<DatabaseEvent> _energySubscription;

  @override
  void initState() {
    super.initState();
    _listenForDailyEnergy();
  }

  @override
  void dispose() {
    _energySubscription.cancel();
    super.dispose();
  }

  void _listenForDailyEnergy() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return; // If the user is not authenticated, stop and set loading to false
      }

      final dbRef = FirebaseDatabase.instance.ref();
      final paths = [
        'SensorReadings',
        'SensorReadings_2',
        'SensorReadings_3',
      ];

      print('Listening for daily energy data...');
      _energySubscription = dbRef.onValue.listen((DatabaseEvent event) async {
        double dailyEnergy = 0.0;

        for (final path in paths) {
          final snapshot = await dbRef.child(path).get();

          if (snapshot.exists) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            final DateTime now = DateTime.now();

            data.forEach((key, value) {
              // Print the data for debugging purposes
              print('Data received: $value');

              // Check if value is a valid Map and contains necessary keys
              if (value != null &&
                  value is Map &&
                  value.containsKey('uid') &&
                  value.containsKey('energy') &&
                  value.containsKey('timestamp')) {
                // Only process the data for the current user
                if (value['uid'] == user.uid) {
                  final timestamp = value['timestamp'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          (value['timestamp'] ?? 0) * 1000)
                      : DateTime(
                          0); // Fallback to DateTime(0) if timestamp is missing

                  final DateTime now = DateTime.now();

                  // Check if the timestamp corresponds to today's date
                  if (timestamp.year == now.year &&
                      timestamp.month == now.month &&
                      timestamp.day == now.day) {
                    // Add the energy value to the daily energy total
                    dailyEnergy += (value['energy'] ?? 0.0).toDouble();
                  }
                }
              }
            });
          }
        }

        if (mounted) {
          setState(() {
            _totalDailyEnergy = dailyEnergy;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error fetching daily energy: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRadialGauge(
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  radius: 150,
                  value: _totalDailyEnergy, // Set the gauge value
                  axis: GaugeAxis(
                    min: 0,
                    max: 7,
                    degrees: 180,
                    style: const GaugeAxisStyle(
                      thickness: 21,
                      background: Color(0xFFDFE2EC),
                      segmentSpacing: 3,
                    ),
                    progressBar: GaugeProgressBar.rounded(
                      gradient: const GaugeAxisGradient(
                        colors: [
                          Color.fromARGB(255, 69, 204, 73),
                          Color.fromARGB(255, 202, 60, 41),
                        ],
                      ),
                    ),
                  ),
                ),
                // Existing UI remains unchanged
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 72, 100, 68),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_totalDailyEnergy.toStringAsFixed(3)}',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _totalDailyEnergy >= 6
                                ? Colors.red
                                : _totalDailyEnergy >= 5
                                    ? Colors.deepOrangeAccent
                                    : _totalDailyEnergy >= 4
                                        ? const Color.fromARGB(
                                            255, 245, 179, 93)
                                        : _totalDailyEnergy >= 3
                                            ? const Color.fromARGB(
                                                255, 150, 221, 36)
                                            : _totalDailyEnergy >= 2
                                                ? const Color.fromARGB(
                                                    255, 131, 223, 78)
                                                : _totalDailyEnergy >= 1
                                                    ? const Color.fromARGB(
                                                        255, 132, 247, 79)
                                                    : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'kWh',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _totalDailyEnergy == 0.00
                          ? 'No Energy Consumed'
                          : _totalDailyEnergy <= 2
                              ? 'Low Energy Consumption'
                              : _totalDailyEnergy > 2 && _totalDailyEnergy <= 4
                                  ? 'Average Energy Consumption'
                                  : _totalDailyEnergy > 4 &&
                                          _totalDailyEnergy <= 6
                                      ? 'High Energy Consumption'
                                      : 'Extremely High Consumption',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        color: _totalDailyEnergy == 0
                            ? Colors.grey
                            : _totalDailyEnergy <= 2
                                ? Colors.green
                                : _totalDailyEnergy > 2 &&
                                        _totalDailyEnergy <= 4
                                    ? const Color.fromARGB(255, 115, 180, 9)
                                    : _totalDailyEnergy > 4 &&
                                            _totalDailyEnergy <= 6
                                        ? Colors.orange
                                        : Colors.red,
                      ),
                    ),
                  ],
                ),
                // Keep gauge labels unchanged
                Positioned(
                  top: 135,
                  left: 30,
                  child: const Text('0',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 95,
                  left: 45,
                  child: const Text('1',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 55,
                  left: 75,
                  child: const Text('2',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 30,
                  left: 120,
                  child: const Text('3',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 30,
                  left: 168,
                  child: const Text('4',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 55,
                  left: 220,
                  child: const Text('5',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 95,
                  left: 250,
                  child: const Text('6',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 135,
                  left: 260,
                  child: const Text('7',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }
}
