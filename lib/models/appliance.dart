// appliance.dart
import 'package:flutter/material.dart';

class Appliance {
  final String name;
  final IconData icon;
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimehr;
  final int runtimemin;
  final int runtimesec;
  bool isApplianceOn; // Make mutable to allow instant toggle
  final String documentId;
  final String serialNumber;
  final ValueChanged<bool> onToggleChanged;
  String dbPath;

  Appliance({
    required this.name,
    required this.icon,
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimehr,
    required this.runtimemin,
    required this.runtimesec,
    required this.isApplianceOn,
    required this.documentId,
    required this.serialNumber,
    required this.onToggleChanged,
    this.dbPath = 'SensorReadings',
  });
}
