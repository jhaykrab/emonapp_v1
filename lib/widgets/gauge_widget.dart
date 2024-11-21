import 'dart:async'; // Import StreamSubscription
import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GaugeWidget extends StatefulWidget {
  const GaugeWidget({Key? key}) : super(key: key);

  @override
  _GaugeWidgetState createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget> {
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  bool _isResetEnabled = true; // Controls Reset button state
  late StreamSubscription<DatabaseEvent> _energySubscription; // Subscription

  @override
  void initState() {
    super.initState();
    _listenForEnergyChanges(); // Start listening in initState
  }

  @override
  void dispose() {
    _energySubscription
        .cancel(); // Cancel the listener when the widget is disposed
    super.dispose();
  }

  void _listenForEnergyChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref();
        final paths = [
          'SensorReadings',
          'SensorReadings_2',
          'SensorReadings_3'
        ];

        _energySubscription = dbRef.onValue.listen((DatabaseEvent event) async {
          double totalEnergy = 0;
          for (final path in paths) {
            final snapshot = await dbRef.child(path).get();

            if (snapshot.exists) {
              final data = snapshot.value as Map<dynamic, dynamic>;

              if (data['uid'] == user.uid) {
                totalEnergy += (data['energy'] ?? 0.0).toDouble();

                // Check resetEnergy to toggle button state
                bool resetEnergy = data['resetEnergy'] ?? false;
                setState(() {
                  _isResetEnabled =
                      !resetEnergy; // Reset button enabled if resetEnergy is false
                });
              }
            }
          }

          if (mounted) {
            setState(() {
              _totalEnergy = totalEnergy;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error fetching total energy: $e');
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
      child: _isLoading // Conditionally render loader or gauge
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.center,
              children: [
                AnimatedRadialGauge(
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  radius: 150,
                  value: _totalEnergy, // Use the total energy value
                  axis: GaugeAxis(
                    min: 0,
                    max: 7, // Set max value back to 7
                    degrees: 180,
                    style: const GaugeAxisStyle(
                      thickness: 21,
                      background: Color(0xFFDFE2EC),
                      segmentSpacing: 3,
                    ),
                    progressBar: GaugeProgressBar.rounded(
                      color: null,
                      gradient: const GaugeAxisGradient(
                        colors: [
                          Color.fromARGB(255, 69, 204, 73),
                          Color.fromARGB(255, 202, 60, 41)
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 50),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 72, 100, 68),
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_totalEnergy.toStringAsFixed(3)}', // Display total energy
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _totalEnergy >= 6 // Updated color conditions
                                ? Colors.red
                                : _totalEnergy >= 5
                                    ? Colors.deepOrangeAccent
                                    : _totalEnergy >= 4
                                        ? const Color.fromARGB(
                                            255, 245, 179, 93)
                                        : _totalEnergy >= 3
                                            ? const Color.fromARGB(
                                                255, 150, 221, 36)
                                            : _totalEnergy >= 2
                                                ? const Color.fromARGB(
                                                    255, 131, 223, 78)
                                                : _totalEnergy >= 1
                                                    ? const Color.fromARGB(
                                                        255, 132, 247, 79)
                                                    : Colors.green,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'kWh',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      _totalEnergy == 0.00
                          ? 'No Energy Consumed'
                          : _totalEnergy <= 2 // Updated text conditions
                              ? 'Low Energy Consumption'
                              : _totalEnergy > 2 && _totalEnergy <= 4
                                  ? 'Average Energy Consumption'
                                  : _totalEnergy > 4 && _totalEnergy <= 6
                                      ? 'High Energy Consumption'
                                      : 'Extremely High Consumption',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        color: _totalEnergy == 0
                            ? Colors.grey
                            : _totalEnergy <= 2
                                ? Colors.green
                                : _totalEnergy > 2 && _totalEnergy <= 4
                                    ? const Color.fromARGB(255, 115, 180, 9)
                                    : _totalEnergy > 4 && _totalEnergy <= 6
                                        ? Colors.orange
                                        : Colors.red,
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
                // Adjusted positions and font sizes for the gauge labels
                Positioned(
                  top: 135, // Moved down by 20
                  left: 30, // Moved right by 50
                  child: Text('0',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 95, // Moved down by 20
                  left: 45, // Moved right by 50
                  child: Text('1',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 55, // Moved down by 20
                  left: 75, // Moved right by 50
                  child: Text('2',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 30, // Moved down by 20
                  left: 120, // Moved right by 50
                  child: Text('3',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 30, // Moved down by 20
                  left: 168, // Moved right by 50
                  child: Text('4',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 55, // Moved down by 20
                  left: 220, // Moved right by 50
                  child: Text('5',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 95, // Moved down by 20
                  left: 250, // Moved right by 50
                  child: Text('6',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  top: 135, // Moved down by 20
                  left: 260, // Moved right by 50
                  child: Text('7',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
