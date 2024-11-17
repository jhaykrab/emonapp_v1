// appliance.dart
import 'package:flutter/material.dart';
import 'package:Emon/constants.dart'; // Import your constants file

class Appliance {
  String name;
  String applianceType;
  // Make 'icon' a getter
  IconData get icon => applianceIcons[applianceType] ?? Icons.device_unknown;
  double energy;
  double voltage;
  double current;
  double power;
  int runtimehr;
  int runtimemin;
  int runtimesec;
  bool isApplianceOn;
  String documentId;
  String serialNumber;
  final Function(bool) onToggleChanged;
  String dbPath;

  Appliance({
    required this.name,
    required this.applianceType,
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
    required this.dbPath,
  });

  Appliance copyWith({
    String? name,
    String? applianceType, // Include applianceType in copyWith
    double? energy,
    double? voltage,
    double? current,
    double? power,
    int? runtimehr,
    int? runtimemin,
    int? runtimesec,
    bool? isApplianceOn,
    String? documentId,
    String? serialNumber,
    Function(bool)? onToggleChanged,
    String? dbPath,
  }) {
    return Appliance(
      name: name ?? this.name,
      applianceType: applianceType ?? this.applianceType,
      energy: energy ?? this.energy,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      power: power ?? this.power,
      runtimehr: runtimehr ?? this.runtimehr,
      runtimemin: runtimemin ?? this.runtimemin,
      runtimesec: runtimesec ?? this.runtimesec,
      isApplianceOn: isApplianceOn ?? this.isApplianceOn,
      documentId: documentId ?? this.documentId,
      serialNumber: serialNumber ?? this.serialNumber,
      onToggleChanged: onToggleChanged ?? this.onToggleChanged,
      dbPath: dbPath ?? this.dbPath,
    );
  }
}
