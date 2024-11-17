// device_info_widget.dart
import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:Emon/providers/appliance_provider.dart';
import 'package:Emon/models/appliance.dart';
import 'package:Emon/constants.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'dart:async';

class DeviceInfoWidget extends StatefulWidget {
  final List<Appliance> appliances;
  final Function(Appliance) onAddAppliance;

  const DeviceInfoWidget(
      {Key? key, required this.appliances, required this.onAddAppliance})
      : super(key: key);

  @override
  _DeviceInfoWidgetState createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget> {
  DateTime? _serverDate;
  late Future<void> _serverDateFuture;

  final TextEditingController _editNameController = TextEditingController();
  IconData? _selectedEditIcon;

  @override
  void initState() {
    super.initState();
    _serverDateFuture = _fetchServerDate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApplianceProvider>(context, listen: false)
          .listenToRealtimeData();
    });
  }

  Future<void> _fetchServerDate() async {
    try {
      DocumentReference<Map<String, dynamic>> serverTimestampRef =
          FirebaseFirestore.instance.collection('server').doc('timestamp');
      await serverTimestampRef.set({'timestamp': FieldValue.serverTimestamp()});
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await serverTimestampRef.get();
      Timestamp timestamp = snapshot['timestamp'] as Timestamp;
      _serverDate = timestamp.toDate();

      Provider.of<ApplianceProvider>(context, listen: false).isLoading = false;

      setState(() {});
    } catch (e) {
      print('Error fetching server timestamp: $e');
    }
  }

  String _getDbPathForSerialNumber(String serialNumber) {
    switch (serialNumber) {
      case '11032401':
        return 'SensorReadings';
      case '11032402':
        return 'SensorReadings_2';
      case '11032403':
        return 'SensorReadings_3';
      default:
        return ''; // Or a default path if needed
    }
  }

  Widget _buildApplianceRow(Appliance appliance, int index) {
    final applianceProvider = Provider.of<ApplianceProvider>(context);
    const int maxNameLength = 15;

    String dbPath = _getDbPathForSerialNumber(appliance.serialNumber);

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref(dbPath).onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          bool isApplianceOn = data['applianceState'] ?? false;
          int runtimeHours = data['runtimehr'] ?? 0;
          int runtimeMinutes = data['runtimemin'] ?? 0;
          int runtimeSeconds = data['runtimesec'] ?? 0;

          return _buildApplianceListContainer(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      appliance.icon,
                      size: 32,
                      color: const Color.fromARGB(255, 72, 100, 68),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.wifi,
                      size: 18,
                      color: isApplianceOn ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MouseRegion(
                          onEnter: (_) => setState(() {}),
                          onExit: (_) => setState(() {}),
                          child: Tooltip(
                            message: appliance.name,
                            preferBelow: false,
                            child: Text(
                              appliance.name.length > maxNameLength
                                  ? '${appliance.name.substring(0, maxNameLength)}...'
                                  : appliance.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Serial No: ${appliance.serialNumber}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isApplianceOn ? 'Device On' : 'Device Off',
                          style: TextStyle(
                            fontSize: 12,
                            color: isApplianceOn
                                ? Colors.green
                                : const Color.fromARGB(
                                    255, 126, 125, 125), // Conditional color
                          ),
                        ),
                        Text(
                          // Display runtime below Device On/Off
                          'Runtime: $runtimeHours hrs $runtimeMinutes mins $runtimeSeconds secs',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value:
                                isApplianceOn, // Use isApplianceOn from Realtime DB
                            onChanged: (value) async {
                              await applianceProvider.toggleAppliance(
                                  appliance, value);
                            },
                            activeTrackColor: Colors.green[700],
                            activeColor: Colors.green[900],
                            inactiveTrackColor: Colors.grey[400],
                            inactiveThumbColor: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(appliance, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _showRemoveConfirmationDialog(appliance),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return _buildApplianceListContainer(Text('Error: ${snapshot.error}'));
        } else {
          return _buildApplianceListContainer(
              const Center(child: CircularProgressIndicator()));
        }
      },
    );
  }

  Widget _buildApplianceListContainer(Widget child) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 236, 219),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Function to build the container for DeviceInfoWidget
  Widget _buildDeviceInfoContainer(Widget child) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      padding: EdgeInsets.all(8.0),
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 236, 219),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: Container(
              // This is the main container for date, refresh button, and list
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(top: 20.0),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 243, 250, 244),
                border: Border.all(color: Colors.grey[300]!, width: 1.0),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // For aligning items to the edges
                    children: [
                      Expanded(
                        // This Expanded widget pushes the Text to the right
                        child: Align(
                          alignment:
                              Alignment.center, // Align the Text to the right
                          child: Text(
                            _serverDate != null
                                ? DateFormat('MMMM d, yyyy - EEEE')
                                    .format(_serverDate!)
                                : 'Loading date...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          // 1. Navigate to ApplianceListScreen and wait for the result
                          final result = await Navigator.pushNamed(
                              context, ApplianceListScreen.routeName);

                          // 2. Check the result; pop only if navigation was successful
                          if (result != null) {
                            // Check if a result was returned (meaning the page was popped)
                            Timer(const Duration(seconds: 1), () {
                              Navigator.pop(context);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder(
                    future: _serverDateFuture, // Use the initialized future
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Show loader while fetching
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}'); // Handle error
                      } else {
                        return Consumer<ApplianceProvider>(
                          builder: (context, applianceProvider, child) {
                            return Column(
                              children: applianceProvider.appliances
                                  .asMap()
                                  .entries
                                  .map((entry) => _buildApplianceRow(
                                      entry.value, entry.key))
                                  .toList(),
                            );
                          },
                        );
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetupApplianceScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                      foregroundColor: const Color(0xFFe8f5e9),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 6),
                        Text('Add Appliance'),
                      ],
                    ),
                  ),
                ], // Column children
              ),
            ),
          ),
        ], // Column children
      ),
    );
  }

  Future<void> _showRemoveConfirmationDialog(Appliance appliance) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Remove Appliance',
            style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to remove this appliance?',
                  style: TextStyle(color: Color.fromARGB(255, 22, 22, 22)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Color.fromARGB(255, 114, 18, 18)),
              ),
              onPressed: () async {
                final applianceProvider =
                    Provider.of<ApplianceProvider>(context, listen: false);
                try {
                  // 1. Remove from UI immediately
                  applianceProvider.removeAppliance(appliance);

                  // 2. THEN remove from Firestore and Realtime Database
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('registered_appliances')
                      .doc(appliance.documentId)
                      .delete();

                  final dbRef = FirebaseDatabase.instance.ref();
                  final paths = [
                    'SensorReadings',
                    'SensorReadings_2',
                    'SensorReadings_3',
                  ];

                  for (final path in paths) {
                    final snapshot =
                        await dbRef.child('$path/serialNumber').get();
                    if (snapshot.value != null &&
                        snapshot.value.toString() == appliance.serialNumber) {
                      await dbRef.child('$path/uid').remove();
                      print('UID removed from $path');
                      break;
                    }
                  }

                  // 3. Close the dialog
                  Navigator.pop(context); // Correctly pops the dialog

                  // 4. Show SnackBar after UI update and dialog dismissal

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        // Row for icon and text
                        children: const [
                          Icon(Icons.check_circle,
                              color: const Color.fromARGB(255, 54, 83, 56)),
                          SizedBox(width: 8),
                          Text(
                            'Appliance removed successfully!',
                            style: TextStyle(
                                color: const Color.fromARGB(
                                    255, 54, 83, 56)), // White text
                          ),
                        ],
                      ),
                      backgroundColor: const Color.fromARGB(255, 211, 243, 213),
                      behavior: SnackBarBehavior.floating, // Floating behavior
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Rounded corners
                      ),
                      margin: const EdgeInsets.only(
                          bottom: 20.0, left: 15.0, right: 15.0), // Margins
                      duration: const Duration(seconds: 2), //Optional duration
                    ),
                  );
                } catch (e) {
                  print('Error removing appliance: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.error,
                              color: Color.fromARGB(
                                  255, 110, 36, 36)), // White icon
                          SizedBox(width: 8),
                          Text('Failed to remove appliance.',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 110, 36, 36))),
                        ],
                      ),
                      backgroundColor: const Color.fromARGB(
                          255, 243, 208, 206), // Lighter red
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.only(
                          bottom: 20, left: 15, right: 15),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Appliance appliance, int index) async {
    _editNameController.text = appliance.name;
    String selectedApplianceType = appliance.applianceType;
    _selectedEditIcon = appliance.icon;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Edit Appliance',
            style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editNameController,
                  decoration: const InputDecoration(
                    labelText: 'Appliance Name',
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 54, 83, 56),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButton<String>(
                      value: selectedApplianceType,
                      icon: const Icon(Icons.arrow_drop_down),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedApplianceType = newValue!;
                          _selectedEditIcon = applianceIcons[newValue];
                        });
                      },
                      items: applianceIcons.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                final applianceProvider =
                    Provider.of<ApplianceProvider>(context, listen: false);
                // Call editAppliance *here* after user confirms
                await applianceProvider.editAppliance(
                  appliance,
                  _editNameController.text,
                  _selectedEditIcon!, // Pass _selectedEditIcon twice
                );

                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
              ),
            ),
          ],
        );
      },
    );
  }
}
