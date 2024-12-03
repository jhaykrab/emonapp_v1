import 'dart:async'; // Import StreamSubscription
import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GaugeWidget extends StatefulWidget {
  final double energy; // Current energy value to display
  final ValueChanged<double>
      onEnergyUpdate; // Callback to notify parent of energy changes

  const GaugeWidget({
    Key? key,
    required this.energy,
    required this.onEnergyUpdate,
  }) : super(key: key);

  @override
  _GaugeWidgetState createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget> {
  late StreamSubscription<DatabaseEvent>
      _energySubscription; // Subscription to real-time energy data
  bool _isLoading = true;
  bool _isResetEnabled = true; // Controls Reset button state

  @override
  void initState() {
    super.initState();
    _listenForEnergyChanges(); // Start listening to energy changes
  }

  @override
  void dispose() {
    _energySubscription.cancel(); // Cancel the listener on widget disposal
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
          'SensorReadings_3',
        ];

        _energySubscription = dbRef.onValue.listen((DatabaseEvent event) async {
          double totalEnergy = 0.0;
          for (final path in paths) {
            final snapshot = await dbRef.child(path).get();

            if (snapshot.exists) {
              final data = snapshot.value as Map<dynamic, dynamic>;
              if (data['uid'] == user.uid) {
                totalEnergy += (data['energy'] ?? 0.0).toDouble();

                // Check resetEnergy to toggle Reset button state
                bool resetEnergy = data['resetEnergy'] ?? false;
                setState(() {
                  _isResetEnabled = !resetEnergy;
                });
              }
            }
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });

            // Notify parent of the updated energy value
            widget.onEnergyUpdate(totalEnergy);
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
                  value: widget.energy, // Use the energy value from the parent
                  axis: GaugeAxis(
                    min: 0,
                    max: 7, // Maximum value for the gauge
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
                          Color.fromARGB(255, 202, 60, 41),
                        ],
                      ),
                    ),
                  ),
                ),
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
                          '${widget.energy.toStringAsFixed(3)}', // Display the total energy value
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: widget.energy >= 6
                                ? Colors.red
                                : widget.energy >= 5
                                    ? Colors.deepOrangeAccent
                                    : widget.energy >= 4
                                        ? const Color.fromARGB(
                                            255, 245, 179, 93)
                                        : widget.energy >= 3
                                            ? const Color.fromARGB(
                                                255, 150, 221, 36)
                                            : widget.energy >= 2
                                                ? const Color.fromARGB(
                                                    255, 131, 223, 78)
                                                : widget.energy >= 1
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
                      widget.energy == 0.00
                          ? 'No Energy Consumed'
                          : widget.energy <= 2
                              ? 'Low Energy Consumption'
                              : widget.energy > 2 && widget.energy <= 4
                                  ? 'Average Energy Consumption'
                                  : widget.energy > 4 && widget.energy <= 6
                                      ? 'High Energy Consumption'
                                      : 'Extremely High Consumption',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        color: widget.energy == 0
                            ? Colors.grey
                            : widget.energy <= 2
                                ? Colors.green
                                : widget.energy > 2 && widget.energy <= 4
                                    ? const Color.fromARGB(255, 115, 180, 9)
                                    : widget.energy > 4 && widget.energy <= 6
                                        ? Colors.orange
                                        : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                Positioned(
                  top: 135,
                  left: 30,
                  child: const Text(
                    '0',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 95,
                  left: 45,
                  child: const Text(
                    '1',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 55,
                  left: 75,
                  child: const Text(
                    '2',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 120,
                  child: const Text(
                    '3',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 30,
                  left: 168,
                  child: const Text(
                    '4',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 55,
                  left: 220,
                  child: const Text(
                    '5',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 95,
                  left: 250,
                  child: const Text(
                    '6',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  top: 135,
                  left: 260,
                  child: const Text(
                    '7',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
