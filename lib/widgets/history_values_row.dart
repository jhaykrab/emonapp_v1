import 'package:flutter/material.dart';

class HistoryValuesRow extends StatelessWidget {
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimeHr;
  final int runtimeMin;
  final int runtimeSec;

  const HistoryValuesRow({
    Key? key,
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimeHr,
    required this.runtimeMin,
    required this.runtimeSec,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Icon(
          Icons.lightbulb, // Replace with device icon
          size: 40,
          color: const Color.fromARGB(255, 72, 100, 68),
        ),
        SizedBox(width: 10, height: 60),
        _buildValueText(energy.toStringAsFixed(1)),
        _buildValueText(voltage.toStringAsFixed(1)),
        _buildValueText(current.toStringAsFixed(1)),
        _buildValueText(power.toStringAsFixed(1)),
        _buildValueText('$runtimeHr: $runtimeMin: $runtimeSec'),
      ],
    );
  }

  // Helper function to build individual value Text widgets
  Widget _buildValueText(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
    );
  }
}
