import 'package:flutter/material.dart';

class HistoryLabelsRow extends StatelessWidget {
  const HistoryLabelsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 75),
        _buildLabelText('kWh'),
        SizedBox(width: 43),
        _buildLabelText('V'),
        SizedBox(width: 60),
        _buildLabelText('A'),
        SizedBox(width: 30),
        SizedBox(width: 20),
        _buildLabelText('W'),
        SizedBox(width: 25),
        SizedBox(width: 25),
        _buildLabelText('Runtime'),
      ],
    );
  }

  // Helper function to build individual label Text widgets
  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
    );
  }
}
