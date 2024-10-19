import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Database

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isApplianceOn = false;

  // Firebase Realtime Database reference
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('SensorReadings');

  // Variables to store energy data
  double _voltage = 0.0;
  double _current = 0.0;
  double _power = 0.0;
  double _energy = 0.0;

  @override
  void initState() {
    super.initState();

    // Listen for changes to all sensor readings
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      setState(() {
        _voltage = (data?['voltage'] ?? 0.0).toDouble();
        _current = (data?['current'] ?? 0.0).toDouble();
        _power = (data?['power'] ?? 0.0).toDouble();
        _energy = (data?['energy'] ?? 0.0).toDouble();
        _isApplianceOn = data?['applianceState'] ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display real-time energy data
            Text('Voltage: ${_voltage.toStringAsFixed(2)} V'),
            Text('Current: ${_current.toStringAsFixed(2)} A'),
            Text('Power: ${_power.toStringAsFixed(2)} W'),
            Text('Total Energy: ${_energy.toStringAsFixed(2)} kWh'),

            // Add charts (e.g., using fl_chart or syncfusion_flutter_charts)
            // ... (your code for charts)

            // Toggle button to control the appliance with green theme
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isApplianceOn ? 'Appliance On' : 'Appliance Off'),
                const SizedBox(width: 10),
                Switch(
                  value: _isApplianceOn,
                  onChanged: (value) {
                    setState(() {
                      _isApplianceOn = value;
                      // Update Firebase database with the new appliance state
                      _databaseRef.update({'applianceState': _isApplianceOn});
                    });
                  },
                  activeTrackColor: Colors.green[700],
                  activeColor: Colors.green[900],
                  inactiveTrackColor: Colors.grey[400],
                  inactiveThumbColor: Colors.grey[300],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
