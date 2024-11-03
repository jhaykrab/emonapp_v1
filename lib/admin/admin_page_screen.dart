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
  List<String> _serialNumbers = [];
  bool _isMigrating = false;
  bool _showSerialNumbers = false;
  String _fetchedSerialNumber = '';

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

              // Container to display fetched serial numbers
              if (_showSerialNumbers)
                Container(
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
                        'Fetched Serial Number:', // Changed to singular
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fetchedSerialNumber, // Display the fetched serial number
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isMigrating || _serialNumbers.isEmpty
                    ? null
                    : _migrateToFirestore,
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
      _showSerialNumbers = true;
    });

    // Fetch the serial number from Realtime Database
    _fetchedSerialNumber = await fetchSerialNumber();

    setState(() {
      _isMigrating = false;
    });
  }

  Future<void> _migrateToFirestore() async {
    setState(() {
      _isMigrating = true; // Set migrating flag to true
    });
    await migrateSerialNumbersToFirestore(_serialNumbers);
    setState(() {
      _isMigrating = false; // Set migrating flag to false
    });
  }

  // Function to fetch the serial number from Realtime Database
  Future<String> fetchSerialNumber() async {
    try {
      DatabaseEvent snapshot =
          await databaseRef.child('SensorReadings/serialNumber').once();

      if (snapshot.snapshot.value != null) {
        return snapshot.snapshot.value.toString();
      } else {
        return 'Serial number not found'; // Return a message if not found
      }
    } catch (e) {
      print('Error fetching serial number: $e');
      _showErrorDialog("Error", "Failed to fetch serial number.");
      return 'Error fetching serial number';
    }
  }

  // Function to migrate serial numbers to Firestore
  Future<void> migrateSerialNumbersToFirestore(
      List<String> serialNumbers) async {
    final firestore = FirebaseFirestore.instance;
    for (String serialNumber in serialNumbers) {
      try {
        // Create a new document in Firestore with the serial number as the document ID
        await firestore.collection('devices').doc(serialNumber).set({
          'serialNumber': serialNumber,
          // Add other device data if needed
        });
        print('Migrated serial number: $serialNumber');
      } catch (e) {
        print('Error migrating serial number $serialNumber: $e');
        _showErrorDialog(
            "Error", "Failed to migrate serial number $serialNumber.");
      }
    }
    _showSuccessDialog("Success", "Serial numbers migrated to Firestore.");
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
