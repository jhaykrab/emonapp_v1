import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // Import math library for animation
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:Emon/screens/dashboard_screen.dart';
import 'package:Emon/widgets/device_info_widget.dart';


class ApplianceReadingsRow extends StatelessWidget {
  final IconData applianceIcon;
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimehr;
  final int runtimemin;
  final int runtimesec;
  final bool isApplianceOn;
  final ValueChanged<bool> onToggleChanged;

  const ApplianceReadingsRow({
    Key? key,
    required this.applianceIcon,
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimehr,
    required this.runtimemin,
    required this.runtimesec,
    required this.isApplianceOn,
    required this.onToggleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Icon(
          applianceIcon,
          size: 36,
          color: const Color.fromARGB(255, 72, 100, 68),
        ),
        _buildReadingValue(energy.toStringAsFixed(2)),
        _buildReadingValue(voltage.toStringAsFixed(1)),
        _buildReadingValue(current.toStringAsFixed(2)),
        _buildReadingValue(power.toStringAsFixed(1)),
        _buildReadingValue('${runtimehr}:${runtimemin}:${runtimesec}'),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isApplianceOn,
            onChanged: onToggleChanged,
            activeTrackColor: Colors.green[700],
            activeColor: Colors.green[900],
            inactiveTrackColor: Colors.grey[400],
            inactiveThumbColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  // Helper function to build reading values
  Widget _buildReadingValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
    );
  }
}
