import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/screens/SplashScreen.dart';

// Define an Appliance class to hold data for each appliance
class Appliance {
  final String name; // Add appliance name
  final IconData icon; // Add appliance icon
  final double serialNumber;
  final bool isApplianceOn;
  final ValueChanged<bool> onToggleChanged;
  final String documentId; // Add documentId

  Appliance({
    required this.name, // Initialize name
    required this.icon, // Initialize icon
    required this.serialNumber,
    required this.isApplianceOn,
    required this.onToggleChanged,
    required this.documentId,
  });
}

class AdminPage extends StatefulWidget {
  static const String routeName = '/adminPage';

  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  List<String> _allSerialNumbers = []; // List to store all serial numbers
  bool _isMigrating = false;
  bool _showSerialNumbers = false;
  bool _isFetching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 72, 100, 68),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 243, 250, 244),
        elevation: 0,
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf5f5f5), Color(0xFFe8f5e9)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isMigrating ? null : _fetchSerialNumbers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                  padding:
                      const EdgeInsets.symmetric(vertical: 17, horizontal: 80),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: const Text(
                  'Fetch Serial Numbers',
                  style: TextStyle(
                    color: Color(0xFFe8f5e9),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Loading Indicator or Container
              _isFetching
                  ? const CircularProgressIndicator() // Show loading indicator
                  : _showSerialNumbers
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device Serial List:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Display all fetched serial numbers
                              for (int i = 0; i < _allSerialNumbers.length; i++)
                                Text(
                                  'Device_${i + 1}: ${_allSerialNumbers[i]}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isMigrating ? null : _migrateToFirestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                  padding:
                      const EdgeInsets.symmetric(vertical: 17, horizontal: 98),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: const Text(
                  'Migrate to Firestore',
                  style: TextStyle(
                    color: Color(0xFFe8f5e9),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchSerialNumbers() async {
    setState(() {
      _isMigrating = true;
      _isFetching = true;
    });

    _allSerialNumbers = await fetchAllSerialNumbers();

    setState(() {
      _isMigrating = false;
      _isFetching = false;
      _showSerialNumbers = _allSerialNumbers.isNotEmpty; // Show if data exists

      // Show error if no data is fetched
      if (_allSerialNumbers.isEmpty) {
        _showErrorDialog("Error", "No serial numbers found.");
      }
    });
  }

  Future<void> _migrateToFirestore() async {
    setState(() {
      _isMigrating = true; // Set migrating flag to true
    });

    await migrateAllSerialNumbersToFirestore(_allSerialNumbers);

    setState(() {
      _isMigrating = false; // Set migrating flag to false
    });
  }

  // Function to fetch all serial numbers from SensorReadings, SensorReadings_2, SensorReadings_3
  Future<List<String>> fetchAllSerialNumbers() async {
    List<String> allSerialNumbers = [];

    // Fetch from SensorReadings
    allSerialNumbers.addAll(
        await fetchSerialNumbersFromPath('SensorReadings/serialNumber'));

    // Fetch from SensorReadings_2
    allSerialNumbers.addAll(
        await fetchSerialNumbersFromPath('SensorReadings_2/serialNumber'));

    // Fetch from SensorReadings_3
    allSerialNumbers.addAll(
        await fetchSerialNumbersFromPath('SensorReadings_3/serialNumber'));

    return allSerialNumbers;
  }

  // Function to fetch serial numbers from a specific path in Realtime Database
  Future<List<String>> fetchSerialNumbersFromPath(String path) async {
    List<String> serialNumbers = [];
    try {
      DatabaseEvent snapshot = await databaseRef.child(path).once();

      // Check if the snapshot value is not null
      if (snapshot.snapshot.value != null) {
        // Directly get the serial number as a string
        String serialNumber = snapshot.snapshot.value.toString();
        serialNumbers.add(serialNumber);
      }
    } catch (e) {
      print('Error fetching serial numbers from $path: $e');
      _showErrorDialog("Error", "Failed to fetch serial numbers from $path.");
    }
    return serialNumbers;
  }

  // Function to migrate all serial numbers to Firestore
  Future<void> migrateAllSerialNumbersToFirestore(
      List<String> serialNumbers) async {
    final firestore = FirebaseFirestore.instance;
    try {
      for (int i = 0; i < serialNumbers.length; i++) {
        await firestore.collection('admin').doc('emon-devices').set({
          'Device_${i + 1}': serialNumbers[i],
        }, SetOptions(merge: true));

        print('Migrated serial number: ${serialNumbers[i]} to Firestore');
      }
      _showSuccessDialog(
          "Success", "All serial numbers migrated to Firestore.");
    } catch (e) {
      print('Error migrating serial numbers to Firestore: $e');
      _showErrorDialog(
          "Error", "Failed to migrate all serial numbers to Firestore.");
    }
  }

  // Function to show an error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Function to show a success dialog
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Function to sign out the admin
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut(); // Sign out using FirebaseAuth
    // Navigate to SplashScreen after sign-out
    Navigator.pushReplacementNamed(context, SplashScreen.routeName);
  }
}
