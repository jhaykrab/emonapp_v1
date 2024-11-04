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
                        'Device Serial List:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Display serial numbers with device names
                      for (int i = 0; i < _serialNumbers.length; i++)
                        Text(
                          'Device_${i + 1}: ${_serialNumbers[i]}', // Format: Device_01: <serialNumber>
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 10),
                      // Display the fetched serial number (if needed)
                      if (_fetchedSerialNumber.isNotEmpty)
                        RichText(
                          text: TextSpan(
                            text: 'Device_01: ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(
                                  255, 20, 20, 20), // Black for "Device_01"
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: _fetchedSerialNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 72, 100,
                                      68), // Dark green for serial number
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchedSerialNumber.isEmpty
                    ? null
                    : _migrateToFirestore, // Temporarily remove _isMigrating

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
    _serialNumbers = await fetchSerialNumbersFromRTDB();

    setState(() {
      _isMigrating = false;
    });
  }

  Future<void> _migrateToFirestore() async {
    setState(() {
      _isMigrating = true; // Set migrating flag to true
    });

    // Migrate the fetched serial number to Firestore
    await migrateSerialNumberToFirestore(_fetchedSerialNumber);

    // Migrate other serial numbers from the list
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

  // Function to migrate a single serial number to Firestore
  Future<void> migrateSerialNumberToFirestore(String serialNumber) async {
    final firestore = FirebaseFirestore.instance;
    try {
      // Create a new document in Firestore under 'admin/emon-devices'
      await firestore.collection('admin').doc('emon-devices').set(
          {
            'Device_01':
                serialNumber, // Add the serial number with the device name
          },
          SetOptions(
              merge: true)); // Use merge to avoid overwriting existing data

      print('Migrated serial number: $serialNumber to Firestore');
    } catch (e) {
      print('Error migrating serial number $serialNumber to Firestore: $e');
      _showErrorDialog("Error",
          "Failed to migrate serial number $serialNumber to Firestore.");
    }
  }

  // Function to migrate serial numbers to Firestore
  Future<void> migrateSerialNumbersToFirestore(
      List<String> serialNumbers) async {
    final firestore = FirebaseFirestore.instance;
    for (int i = 0; i < serialNumbers.length; i++) {
      try {
        // Create a new document in Firestore under 'admin/emon-devices'
        await firestore.collection('admin').doc('emon-devices').set(
            {
              'Device_${i + 1}': serialNumbers[
                  i], // Add each serial number with its device name
            },
            SetOptions(
                merge: true)); // Use merge to avoid overwriting existing data

        print('Migrated serial number: ${serialNumbers[i]} to Firestore');
      } catch (e) {
        print(
            'Error migrating serial number ${serialNumbers[i]} to Firestore: $e');
        _showErrorDialog("Error",
            "Failed to migrate serial number ${serialNumbers[i]} to Firestore.");
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

  // Function to fetch serial numbers from Realtime Database
  Future<List<String>> fetchSerialNumbersFromRTDB() async {
    List<String> serialNumbers = [];
    try {
      DatabaseEvent snapshot = await databaseRef.child('Serial_Numbers').once();
      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          serialNumbers.add(value.toString());
        });
      }
    } catch (e) {
      print('Error fetching serial numbers: $e');
      _showErrorDialog("Error", "Failed to fetch serial numbers.");
    }
    return serialNumbers;
  }
}
