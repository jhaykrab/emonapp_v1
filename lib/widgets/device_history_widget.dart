import 'package:flutter/material.dart';

class DeviceHistoryItem extends StatelessWidget {
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimeHr;
  final int runtimeMin;
  final int runtimeSec;

  const DeviceHistoryItem({
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimeHr,
    required this.runtimeMin,
    required this.runtimeSec,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Energy: ${energy.toStringAsFixed(2)} kWh',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Voltage: ${voltage.toStringAsFixed(2)} V'),
            Text('Current: ${current.toStringAsFixed(2)} A'),
            Text('Power: ${power.toStringAsFixed(2)} W'),
            SizedBox(height: 8),
            Text(
                'Runtime: ${runtimeHr} hr ${runtimeMin} min ${runtimeSec} sec'),
          ],
        ),
      ),
    );
  }
}
