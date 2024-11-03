import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // Import math library for animation
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart';

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
  final ValueChanged<bool> onToggleChanged;
  final String documentId; // Add documentId

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
    required this.onToggleChanged,
    required this.documentId,
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200), // Adjust shake duration
    );
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
        width: 450,
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
            // Date and Day of the Week
            Center(
              child: Text(
                DateFormat('MMMM d, yyyy - EEEE').format(DateTime.now()),
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

  // Helper function to build a row for each appliance
  Widget _buildApplianceRow(Appliance appliance) {
    const int maxNameLength = 10; // Set the maximum name length to display

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
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
          Icon(
            appliance.icon,
            size: 36,
            color: const Color.fromARGB(255, 72, 100, 68),
          ),
          SizedBox(width: 16),
          // Truncated appliance name with hover effect
          MouseRegion(
            onEnter: (_) => setState(() {}), // No state change on hover
            onExit: (_) => setState(() {}), // No state change on exit
            child: Tooltip(
              message: appliance.name, // Full name in tooltip
              preferBelow: false, // Tooltip will be above if it overlaps
              child: Text(
                appliance.name.length > maxNameLength
                    ? '${appliance.name.substring(0, maxNameLength)}...'
                    : appliance.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
            ),
          ),
          SizedBox(width: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Energy: ${appliance.energy.toStringAsFixed(2)} kWh',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
              Text(
                'Voltage: ${appliance.voltage.toStringAsFixed(1)} V',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
              Text(
                'Current: ${appliance.current.toStringAsFixed(2)} A',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
              Text(
                'Power: ${appliance.power.toStringAsFixed(1)} W',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
              Text(
                'Runtime: ${appliance.runtimehr}:${appliance.runtimemin}:${appliance.runtimesec}',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
            ],
          ),

          Spacer(),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: appliance.isApplianceOn,
              onChanged: appliance.onToggleChanged,
              activeTrackColor: Colors.green[700],
              activeColor: Colors.green[900],
              inactiveTrackColor: Colors.grey[400],
              inactiveThumbColor: Colors.grey[300],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmationDialog(appliance.documentId);
            },
          ),
        ],
      ),
    );
  }

  // Helper function to build reading titles
  Widget _buildReadingTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
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

  // Helper function to build unit labels
  Widget _buildUnit(String unit) {
    return Text(
      unit,
      style: TextStyle(
        fontSize: 10,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
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
