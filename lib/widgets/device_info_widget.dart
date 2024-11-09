import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/services/global_state.dart';
import 'package:provider/provider.dart';

// Define an Appliance class to hold data for each appliance
class Appliance {
  final String name; // Add appliance name
  final IconData icon; // Add appliance icon
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimehr;
  final int runtimemin;
  final int runtimesec;
  final bool isApplianceOn;
  final String documentId; // Add documentId
  final String serialNumber; // Add serial number
  final ValueChanged<bool> onToggleChanged;

  Appliance({
    required this.name, // Initialize name
    required this.icon, // Initialize icon
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimehr,
    required this.runtimemin,
    required this.runtimesec,
    required this.isApplianceOn,
    required this.documentId,
    required this.serialNumber, // Initialize serial number
    required this.onToggleChanged,
  });
}

class DeviceInfoWidget extends StatefulWidget {
  final List<Appliance> appliances; // List to hold appliance data
  final Function(Appliance) onAddAppliance; // Function to add appliances

  const DeviceInfoWidget(
      {Key? key, required this.appliances, required this.onAddAppliance})
      : super(key: key);

  @override
  _DeviceInfoWidgetState createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget>
    with SingleTickerProviderStateMixin {
  bool _showDeleteIcon = false; // Flag to control delete icon visibility
  late AnimationController _animationController; // Animation controller
  final databaseRef = FirebaseDatabase.instance.ref();
  Timestamp? _serverTimestamp;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200), // Adjust shake duration
    );
    _fetchRealtimeData(); // Fetch initial data
    _listenToApplianceState();
    _listenToRealtimeData(); // Listen for updates
    _fetchServerTimestamp(); // Fetch the server timestamp
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 380, // Adjusted width
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 0.0),
        margin: EdgeInsets.only(top: 40.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 243, 250, 244),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date and Day of the Week (Modified)
            Center(
              child: Text(
                _serverTimestamp != null
                    ? DateFormat('MMMM d, yyyy - EEEE')
                        .format(_serverTimestamp!.toDate())
                    : 'Loading date...', // Display while fetching
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Dynamically generate rows for each appliance
            ...widget.appliances.map((appliance) {
              return _buildApplianceRow(appliance);
            }).toList(),

            SizedBox(height: 24),

            // Add and Remove Device Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildElevatedButton(
                  '  Add an Appliance  ',
                  const Color.fromARGB(255, 54, 83, 56),
                  () async {
                    final newAppliance = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupApplianceScreen(),
                      ),
                    );

                    // Check if newAppliance is not null (user saved an appliance)
                    if (newAppliance != null && newAppliance is Appliance) {
                      widget.onAddAppliance(newAppliance);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to fetch the server timestamp from Firestore
  Future<void> _fetchServerTimestamp() async {
    try {
      // Get the server timestamp
      _serverTimestamp = Timestamp.now();

      setState(() {}); // Update the UI
    } catch (e) {
      print('Error fetching server timestamp: $e');
      // Handle errors, e.g., show an error message
    }
  }

  // Helper function to build a row for each appliance
  Widget _buildApplianceRow(Appliance appliance) {
    return Consumer<GlobalState>(
      builder: (context, globalState, child) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
          margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 223, 236, 219),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                // Wrap icon, name, and serial number in a Column
                children: [
                  Icon(
                    appliance.icon,
                    size: 30,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                  SizedBox(height: 4), // Add some spacing
                  // Display the appliance name below the icon
                  Text(
                    appliance.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 72, 100, 68),
                    ),
                  ),
                  SizedBox(height: 4), // Add some spacing
                  // Display the serial number below the name
                  Text(
                    '${appliance.serialNumber}',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color.fromARGB(255, 72, 100, 68),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 30),
              // Column for readings (adjust width as needed)
              SizedBox(
                width: 130, // Adjust width to fit content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadingRow('Energy:',
                        '${appliance.energy.toStringAsFixed(2)} kWh'),
                    _buildReadingRow('Voltage:',
                        '${appliance.voltage.toStringAsFixed(1)} V'), // Added back Voltage
                    _buildReadingRow('Current:',
                        '${appliance.current.toStringAsFixed(2)} A'), // Added back Current
                    _buildReadingRow(
                        'Power:', '${appliance.power.toStringAsFixed(1)} W'),
                    _buildReadingRow('Runtime:',
                        '${appliance.runtimehr}:${appliance.runtimemin}:${appliance.runtimesec}'),
                  ],
                ),
              ),
              Spacer(),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: globalState.isApplianceOn,
                  onChanged: (value) {
                    globalState.isApplianceOn = value;
                    _toggleAppliance(appliance.documentId, value);
                  },
                  activeTrackColor: Colors.green[700],
                  activeColor: Colors.green[900],
                  inactiveTrackColor: Colors.grey[400],
                  inactiveThumbColor: Colors.grey[300],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                iconSize: 24,
                onPressed: () {
                  _showDeleteConfirmationDialog(appliance.documentId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to toggle appliance state in Firestore and Realtime Database
  Future<void> _toggleAppliance(String documentId, bool newValue) async {
    try {
      // Get the current user's UID
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in!');
        return;
      }

      // Update the 'isOn' field in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('registered_appliances')
          .doc(documentId)
          .update({'isOn': newValue});

      // Update the appliance state in Realtime Database
      await databaseRef.child('SensorReadings/applianceState').set(newValue);

      print('Appliance state updated successfully!');
    } catch (e) {
      print('Error updating appliance state: $e');
      // Handle errors, e.g., show an error message
    }
  }

  // Function to fetch Realtime Database readings
  Future<void> _fetchRealtimeData() async {
    try {
      DatabaseEvent event = await databaseRef.child('SensorReadings').once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          // Update the Appliance objects in the list
          for (var i = 0; i < widget.appliances.length; i++) {
            widget.appliances[i] = Appliance(
              name: widget.appliances[i].name,
              icon: widget.appliances[i].icon,
              energy: data['energy']?.toDouble() ?? 0.0,
              voltage: data['voltage']?.toDouble() ?? 0.0,
              current: data['current']?.toDouble() ?? 0.0,
              power: data['power']?.toDouble() ?? 0.0,
              runtimehr: data['runtimehr']?.toInt() ?? 0,
              runtimemin: data['runtimemin']?.toInt() ?? 0,
              runtimesec: data['runtimesec']?.toInt() ?? 0,
              isApplianceOn: data['applianceState'] ?? false,
              serialNumber: widget.appliances[i].serialNumber,
              documentId: widget.appliances[i].documentId,
              onToggleChanged: widget.appliances[i].onToggleChanged,
            );
          }
        });
      }
    } catch (e) {
      print('Error fetching Realtime Database data: $e');
      // Handle errors, e.g., show an error message
    }
  }

  void _listenToApplianceState() {
    databaseRef.child('SensorReadings/applianceState').onValue.listen((event) {
      bool newApplianceState = event.snapshot.value as bool? ?? false;

      // Update the global state
      Provider.of<GlobalState>(context, listen: false).isApplianceOn =
          newApplianceState;
    });
  }

  // Function to listen for Realtime Database updates
  void _listenToRealtimeData() {
    databaseRef.child('SensorReadings').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        _fetchRealtimeData(); // Update the appliance data
      }
    });
  }

  // Helper function to build a row for each reading
  Widget _buildReadingRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12, // Reduced font size
            color: const Color.fromARGB(255, 72, 100, 68),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12, // Reduced font size
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 72, 100, 68),
          ),
        ),
      ],
    );
  }

  // Helper function to build elevated buttons
  Widget _buildElevatedButton(
      String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(160, 40),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }

  // Function to show a confirmation dialog before removing a device
  Future<void> _showDeleteConfirmationDialog(String documentId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Device',
            style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete this device?',
                  style: TextStyle(color: Color.fromARGB(255, 22, 22, 22)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
              ),
              onPressed: () {
                setState(() {
                  _showDeleteIcon = false;
                });
                Navigator.of(context).pop();
                _animationController.reset();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(color: Color.fromARGB(255, 114, 18, 18)),
              ),
              onPressed: () async {
                try {
                  // Get the current user's UID
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    print('User not logged in!');
                    return;
                  }

                  // Delete the document from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('registered_appliances')
                      .doc(documentId)
                      .delete();

                  // Show a success message (optional)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Appliance deleted successfully!',
                            style: TextStyle(
                              color: Color.fromARGB(
                                  255, 54, 83, 56), // Dark green text
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Color.fromARGB(
                          255, 193, 223, 194), // Light green background
                    ),
                  );

                  // Remove the appliance from the list
                  setState(() {
                    widget.appliances.removeWhere(
                        (appliance) => appliance.documentId == documentId);
                  });
                } catch (e) {
                  print('Error deleting appliance: $e');
                  // Handle errors, e.g., show an error message
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
