import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:Emon/providers/appliance_provider.dart'; // Import your appliance provider
import 'package:Emon/models/appliance.dart';
import 'package:Emon/constants.dart'; // Import your constants file

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
  final databaseRef = FirebaseDatabase.instance.ref();
  DateTime? _serverDate; // Store the date as DateTime
  late Future<void> _serverDateFuture; // Future for _fetchServerDate

  // Controllers for editing appliance name and icon
  final TextEditingController _editNameController = TextEditingController();
  IconData? _selectedEditIcon;

  @override
  void initState() {
    super.initState();
    _serverDateFuture = _fetchServerDate(); // Initialize the future

    // Start listening for Realtime Database updates
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

      // Update isLoading in ApplianceProvider
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
        return '';
    }
  }

  Widget _buildApplianceRow(Appliance appliance, int index) {
    final applianceProvider = Provider.of<ApplianceProvider>(context);
    const int maxNameLength = 12; // Set the maximum name length for truncation

    return _buildDeviceInfoContainer(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                appliance.icon,
                size: 30,
                color: const Color.fromARGB(255, 72, 100, 68),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.wifi,
                size: 16,
                color: appliance.isApplianceOn ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Truncated appliance name with tooltip
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Serial: ${appliance.serialNumber}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    child: Consumer<ApplianceProvider>(
                      builder: (context, provider, child) {
                        // Find the appliance in the provider
                        Appliance currentAppliance =
                            provider.appliances.firstWhere(
                          (a) => a.serialNumber == appliance.serialNumber,
                          orElse: () =>
                              appliance, // Return the original appliance if not found
                        );
                        return Text(
                          '${currentAppliance.runtimehr}h ${currentAppliance.runtimemin}m ${currentAppliance.runtimesec}s',
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  Text(
                    appliance.isApplianceOn ? 'Device On' : 'Device Off',
                    style: TextStyle(
                      color: appliance.isApplianceOn
                          ? Colors.green[700]
                          : Colors.red,
                      fontWeight: FontWeight.normal,
                      fontSize: 10,
                    ),
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
                      value: appliance.isApplianceOn,
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
                  const SizedBox(width: 4),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditDialog(appliance, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _showDeleteConfirmationDialog(appliance),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
        Container(
          width: MediaQuery.of(context).size.width * 0.75,
          padding: EdgeInsets.all(8.0),
          margin: EdgeInsets.only(top: 20.0),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 243, 250, 244),
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  _serverDate != null
                      ? DateFormat('MMMM d, yyyy - EEEE')
                          .format(_serverDate!) // Format the DateTime directly
                      : 'Loading date...',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 54, 83, 56)),
                ),
              ),
              SizedBox(height: 6),
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
                              .map((entry) =>
                                  _buildApplianceRow(entry.value, entry.key))
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
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
            ],
          ),
        ),
      ],
    ));
  }

  Future<void> _showDeleteConfirmationDialog(Appliance appliance) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                final applianceDocId = appliance.documentId;
                final applianceSerialNumber = appliance.serialNumber;
                final applianceProvider =
                    Provider.of<ApplianceProvider>(context, listen: false);

                try {
                  // Remove appliance data from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('registered_appliances')
                      .doc(applianceDocId)
                      .delete();

                  // --- Remove UID from Realtime Database ---
                  final DatabaseReference dbRef = FirebaseDatabase.instance
                      .ref(); // Declare dbRef only once
                  List<String> paths = [
                    'SensorReadings',
                    'SensorReadings_2',
                    'SensorReadings_3',
                  ];

                  for (String path in paths) {
                    final DataSnapshot snapshot =
                        await dbRef.child('$path/serialNumber').get();

                    if (snapshot.value != null &&
                        snapshot.value.toString() == applianceSerialNumber) {
                      // Found matching serial number, remove UID field
                      await dbRef.child('$path/uid').remove();
                      print(
                          'UID field removed from Realtime Database path: $path');
                      break; // Stop searching after finding a match
                    }
                  }

                  // Update the _appliances list in the provider
                  applianceProvider.removeAppliance(appliance);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Appliance removed successfully!',
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
                } catch (e) {
                  // Handle errors
                  print('Error removing appliance: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red), // Error icon
                          SizedBox(width: 8),
                          Text(
                            'Failed to remove appliance.',
                            style: TextStyle(
                              color: Colors.white, // White text
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red, // Red background
                    ),
                  );
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Appliance appliance, int index) async {
    _editNameController.text = appliance.name;
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
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 54, 83, 56),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 54, 83, 56),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  // Wrap DropdownButton in StatefulBuilder
                  builder: (context, setState) {
                    return Row(
                      // Use a Row to display the icon and dropdown
                      children: [
                        Expanded(
                          // Expand the dropdown to fill the remaining space
                          child: DropdownButton<IconData>(
                            value: _selectedEditIcon,
                            // Remove the hint text
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                            onChanged: (IconData? newValue) {
                              setState(() {
                                // Call setState of StatefulBuilder
                                _selectedEditIcon = newValue;
                              });
                            },
                            items: applianceIcons.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.value,
                                child: Icon(entry.value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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
                await applianceProvider.editAppliance(
                  appliance,
                  _editNameController.text,
                  _selectedEditIcon!,
                  applianceIcons,
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
