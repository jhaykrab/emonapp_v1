import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isApplianceOn = false;

  // Variables to store energy data
  final double _voltage = 0.0;
  final double _current = 0.0;
  final double _power = 0.0;
  final double _totalEnergy = 0.0;

  // Logic to fetch and update energy data could be implemented here
  // (e.g., using a separate service class for data fetching)

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
            Text('Total Energy: ${_totalEnergy.toStringAsFixed(2)} kWh'),

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
                      // Removed Firebase functionality here (could be added later for remote control)
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
