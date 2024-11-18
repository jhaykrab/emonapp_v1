import 'package:flutter/material.dart';
import 'package:Emon/models/appliance.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/constants.dart';

class ApplianceProvider with ChangeNotifier {
  List<Appliance> _appliances = [];
  bool _isLoading = true; // Add isLoading property, initialize as true

  List<Appliance> get appliances => _appliances;
  bool get isLoading => _isLoading;

  // Add a setter for isLoading
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setAppliances(List<Appliance> appliances) {
    _appliances = appliances;
    _isLoading = false; // Data is loaded, set isLoading to false
    notifyListeners();
  }

  void removeAppliance(Appliance appliance) {
    _appliances.remove(appliance);
    notifyListeners();
  }

  void listenToRealtimeData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _appliances.forEach((appliance) {
        String dbPath = appliance.dbPath;
        FirebaseDatabase.instance.ref(dbPath).onValue.listen((event) {
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            int index = _appliances
                .indexWhere((a) => a.serialNumber == data['serialNumber']);
            if (index != -1) {
              _appliances[index] = _appliances[index].copyWith(
                energy: (data['energy'] ?? 0.0).toDouble(),
                voltage: (data['voltage'] ?? 0.0).toDouble(),
                current: (data['current'] ?? 0.0).toDouble(),
                power: (data['power'] ?? 0.0).toDouble(),
                runtimehr: (data['runtimehr'] ?? 0).toInt(),
                runtimemin: (data['runtimemin'] ?? 0).toInt(),
                runtimesec: (data['runtimesec'] ?? 0).toInt(),
                isApplianceOn: data['applianceState'] ?? false,
              );
              notifyListeners();
            }
          }
        });
      });

      _isLoading = false; // Set isLoading to false after fetching data
      notifyListeners();
    }
  }

  void addAppliance(Appliance appliance) {
    //Define the function
    _appliances.add(appliance);
    notifyListeners();
  }

  Future<void> editAppliance(
      Appliance appliance, String newName, IconData newIcon) async {
    String newApplianceType = applianceIcons.keys.firstWhere(
        (k) => applianceIcons[k] == newIcon,
        orElse: () => 'unknown');

    int index =
        _appliances.indexWhere((a) => a.serialNumber == appliance.serialNumber);
    if (index != -1) {
      _appliances[index] = _appliances[index].copyWith(
        name: newName,
        applianceType: newApplianceType,
        energy: appliance.energy,
        voltage: appliance.voltage,
        current: appliance.current,
        power: appliance.power,
        runtimehr: appliance.runtimehr,
        runtimemin: appliance.runtimemin,
        runtimesec: appliance.runtimesec,
        isApplianceOn: appliance.isApplianceOn,
        documentId: appliance.documentId,
        serialNumber: appliance.serialNumber,
        onToggleChanged: appliance.onToggleChanged,
        dbPath: appliance.dbPath,
      );
      notifyListeners();
    }

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
          .update({
        'applianceName': newName,
        'applianceType': newApplianceType, // Update the appliance type
      });
    } catch (e) {
      print('Error updating appliance in Firestore: $e');
      // Handle errors, e.g., revert the local change and show an error message
    }
  }

  Future<void> toggleAppliance(Appliance appliance, bool newValue) async {
    // 1. Update the appliance state in the provider
    int index =
        _appliances.indexWhere((a) => a.serialNumber == appliance.serialNumber);
    if (index != -1) {
      _appliances[index] = _appliances[index].copyWith(isApplianceOn: newValue);
      notifyListeners();
    }

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
      if (index != -1) {
        _appliances[index] =
            _appliances[index].copyWith(isApplianceOn: !newValue);
        notifyListeners();
      }
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
      if (index != -1) {
        _appliances[index] =
            _appliances[index].copyWith(isApplianceOn: !newValue);
        notifyListeners();
      }
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
