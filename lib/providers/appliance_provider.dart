import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/models/appliance.dart';

class ApplianceProvider with ChangeNotifier {
  List<Appliance> _appliances = [];

  List<Appliance> get appliances => _appliances;

  void setAppliances(List<Appliance> appliances) {
    _appliances = appliances;
    notifyListeners();
  }

  void removeAppliance(Appliance appliance) {
    _appliances.remove(appliance);
    notifyListeners();
  }

  void listenToRealtimeData() {
    for (Appliance appliance in _appliances) {
      String dbPath = _getDbPathForSerialNumber(appliance.serialNumber);

      if (dbPath.isNotEmpty) {
        // Listen for changes in the Realtime Database
        FirebaseDatabase.instance.ref(dbPath).onValue.listen((event) {
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;

            // Update the appliance in the provider
            int index = _appliances
                .indexWhere((a) => a.serialNumber == appliance.serialNumber);
            if (index != -1) {
              _appliances[index] = Appliance(
                name: appliance.name,
                icon: appliance.icon,
                energy: data['energy']?.toDouble() ?? appliance.energy,
                voltage: data['voltage']?.toDouble() ?? appliance.voltage,
                current: data['current']?.toDouble() ?? appliance.current,
                power: data['power']?.toDouble() ?? appliance.power,
                runtimehr: data['runtimehr']?.toInt() ?? appliance.runtimehr,
                runtimemin: data['runtimemin']?.toInt() ?? appliance.runtimemin,
                runtimesec: data['runtimesec']?.toInt() ?? appliance.runtimesec,
                isApplianceOn:
                    data['applianceState'] ?? appliance.isApplianceOn,
                serialNumber: appliance.serialNumber,
                documentId: appliance.documentId,
                onToggleChanged: appliance.onToggleChanged,
                dbPath: dbPath,
              );
              notifyListeners(); // Notify listeners of the change
            }
          }
        });
      }
    }
  }

  Future<void> toggleAppliance(Appliance appliance, bool newValue) async {
    // 1. Update the appliance state in the provider
    appliance.isApplianceOn = newValue;
    notifyListeners();

    // 2. Update Firestore
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in!');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('registered_appliances')
          .doc(appliance.documentId)
          .update({'isOn': newValue});
    } catch (e) {
      print('Error updating appliance state in Firestore: $e');
      // Handle errors, e.g., revert the local change and show an error message
      appliance.isApplianceOn = !newValue;
      notifyListeners();
    }

    // 3. Update Realtime Database
    try {
      String dbPath = _getDbPathForSerialNumber(appliance.serialNumber);
      if (dbPath.isNotEmpty) {
        await FirebaseDatabase.instance
            .ref('$dbPath/applianceState')
            .set(newValue);
        print('Appliance state updated successfully in $dbPath!');
      }
    } catch (e) {
      print('Error updating appliance state in Realtime Database: $e');
      // Handle errors, e.g., revert the local change and show an error message
      appliance.isApplianceOn = !newValue;
      notifyListeners();
    }
  }

  // Helper function to get the Realtime Database path
  String _getDbPathForSerialNumber(String serialNumber) {
    switch (serialNumber) {
      case '11032401':
        return 'SensorReadings';
      case '11032402':
        return 'SensorReadings_2';
      case '11032403':
        return 'SensorReadings_3';
      default:
        return '';
    }
  }
}
