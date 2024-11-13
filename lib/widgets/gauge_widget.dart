import 'package:flutter/material.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:firebase_database/firebase_database.dart';

class GaugeWidget extends StatefulWidget {
  final double value; // Add the value parameter

  const GaugeWidget({Key? key, required this.value}) : super(key: key);

  @override
  State<GaugeWidget> createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget> {
  double _totalEnergy = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTotalEnergy();
  }

  Future<void> _fetchTotalEnergy() async {
    final dbRef = FirebaseDatabase.instance.ref();
    final List<String> paths = [
      'SensorReadings',
      'SensorReadings_2',
      'SensorReadings_3',
    ];

    double total = 0.0;
    for (String path in paths) {
      try {
        final snapshot = await dbRef.child(path).child('energy').get();
        if (snapshot.exists) {
          final energyValue = snapshot.value as double;
          total += energyValue;
        }
      } catch (e) {
        print('Error fetching energy from $path: $e');
      }
    }

    setState(() {
      _totalEnergy = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
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
                    '${_totalEnergy.toStringAsFixed(2)}', // Display total energy
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: _totalEnergy >= 6 // Updated color conditions
                          ? Colors.red
                          : _totalEnergy >= 5
                              ? Colors.deepOrangeAccent
                              : _totalEnergy >= 4
                                  ? const Color.fromARGB(255, 245, 179, 93)
                                  : _totalEnergy >= 3
                                      ? const Color.fromARGB(255, 150, 221, 36)
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 95, // Moved down by 20
            left: 45, // Moved right by 50
            child: Text('1',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 55, // Moved down by 20
            left: 75, // Moved right by 50
            child: Text('2',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 30, // Moved down by 20
            left: 120, // Moved right by 50
            child: Text('3',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 30, // Moved down by 20
            left: 168, // Moved right by 50
            child: Text('4',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 55, // Moved down by 20
            left: 220, // Moved right by 50
            child: Text('5',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 95, // Moved down by 20
            left: 250, // Moved right by 50
            child: Text('6',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 135, // Moved down by 20
            left: 260, // Moved right by 50
            child: Text('7',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          // Removed the label for 8
        ],
      ),
    );
  }
}
