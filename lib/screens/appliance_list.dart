import 'package:flutter/material.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Emon/screens/setup_appliance_screen.dart';

class ApplianceListScreen extends StatefulWidget {
  const ApplianceListScreen({super.key});

  @override
  State<ApplianceListScreen> createState() => _ApplianceListScreenState();
}

class _ApplianceListScreenState extends State<ApplianceListScreen> {
  int _selectedIndex = 1;
  User? _user;
  String _userName = '';
  UserData? _userData;
  bool _isApplianceOn = false; // Track the global appliance state

  // Variables to store runtime values from Realtime Database
  int _runtimeHours = 0;
  int _runtimeMinutes = 0;
  int _runtimeSeconds = 0;
  final DatabaseService _dbService = DatabaseService();

  // Realtime Database reference (same path as in DashboardScreen)
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('SensorReadings');

  // List to store appliance data fetched from Firestore
  List<Map<String, dynamic>> _appliances = [];

  // Controllers for appliance name and icon (for adding/editing)
  final TextEditingController _applianceNameController =
      TextEditingController();
  IconData? _selectedApplianceIcon;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _fetchApplianceData();
    _listenToSensorReadings();
    _listenToRuntime();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      UserData? userData = await _dbService.getUserData(_user!.uid);

      if (mounted) {
        setState(() {
          _userData = userData;
          _userName = userData != null
              ? '${userData.firstName ?? ''} ${userData.lastName ?? ''}'
              : 'User Full Name';
        });
      }
    }
  }

  // Firebase Realtime Database listener for sensor readings
  void _listenToSensorReadings() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      setState(() {
        _isApplianceOn = data?['applianceState'] ?? false;
      });
    });
  }

  // Firebase Realtime Database listener for runtime updates
  void _listenToRuntime() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      setState(() {
        _runtimeHours = data?['runtimehr'] ?? 0;
        _runtimeMinutes = data?['runtimemin'] ?? 0;
        _runtimeSeconds = data?['runtimesec'] ?? 0;
      });
    });
  }

  // Function to fetch appliance data from Firestore
  Future<void> _fetchApplianceData() async {
    if (_user != null) {
      _appliances = await _dbService.getApplianceData(_user!.uid);
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Function to add a new appliance
  Future<void> _addAppliance() async {
    // Show a dialog to get appliance name and icon
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Appliance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _applianceNameController,
                  decoration:
                      const InputDecoration(labelText: 'Appliance Name'),
                ),
                const SizedBox(height: 16),
                DropdownButton<IconData>(
                  value: _selectedApplianceIcon,
                  hint: const Text('Select Icon'),
                  onChanged: (IconData? newValue) {
                    setState(() {
                      _selectedApplianceIcon = newValue;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: Icons.lightbulb_outline,
                      child: Icon(Icons.lightbulb_outline),
                    ),
                    DropdownMenuItem(
                      value: Icons.air,
                      child: Icon(Icons.air),
                    ),
                    DropdownMenuItem(
                      value: Icons.tv,
                      child: Icon(Icons.tv),
                    ),
                    DropdownMenuItem(
                      value: Icons.kitchen,
                      child: Icon(Icons.kitchen),
                    ),
                    // Add more icons as needed
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_applianceNameController.text.isNotEmpty &&
                    _selectedApplianceIcon != null) {
                  // Get the next device number
                  int nextDeviceNumber = (_appliances.length + 1);

                  // Create a map with the appliance data
                  Map<String, dynamic> applianceData = {
                    'icon': _selectedApplianceIcon?.codePoint,
                    'name': _applianceNameController.text,
                    'maxUsageLimit': 0.0, // Default value
                    'unit': 'hrs', // Default value
                    'isOn': false,
                    'isRunning': false,
                    'deviceNumber': '$nextDeviceNumber',
                    'docId':
                        '', // You'll need to update this after adding to Firestore
                    'runtimehr': 0,
                    'runtimemin': 0,
                    'runtimesec': 0,
                  };

                  try {
                    // Add appliance data to Firestore
                    DocumentReference docRef = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('registered_appliances')
                        .add(applianceData);

                    // Update the docId in the applianceData
                    applianceData['docId'] = docRef.id;

                    // Update the _appliances list
                    setState(() {
                      _appliances.add(applianceData);
                    });

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_applianceNameController.text} has been added successfully!',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 54, 83, 56),
                          ),
                        ),
                        backgroundColor:
                            const Color.fromARGB(255, 193, 223, 194),
                      ),
                    );
                  } catch (e) {
                    // Handle errors
                    print('Error adding appliance: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add appliance.'),
                      ),
                    );
                  } finally {
                    // Clear the controllers and selected icon
                    _applianceNameController.clear();
                    _selectedApplianceIcon = null;
                    Navigator.pop(context); // Close the dialog
                  }
                } else {
                  // Show an error message if name or icon is not selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name and select an icon.'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to edit an existing appliance (updated)
  Future<void> _editAppliance(int index) async {
    final appliance = _appliances[index];
    final applianceDocId = appliance['docId'];

    // Set initial values for the controllers and selected icon
    _applianceNameController.text = appliance['name'];
    _selectedApplianceIcon =
        IconData(appliance['icon'], fontFamily: 'MaterialIcons');

    // Show a dialog to edit appliance name, icon, and device number
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Appliance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Device Number Input Field
                TextFormField(
                  initialValue: appliance['deviceNumber']
                      .toString(), // Display current device number
                  decoration: const InputDecoration(labelText: 'Device Number'),
                  keyboardType: TextInputType.number, // Allow only numbers
                  onChanged: (value) {
                    // You can add validation here if needed
                    appliance['deviceNumber'] = 'Device $value';
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _applianceNameController,
                  decoration:
                      const InputDecoration(labelText: 'Appliance Name'),
                ),
                const SizedBox(height: 16),
                DropdownButton<IconData>(
                  value: _selectedApplianceIcon,
                  hint: const Text('Select Icon'),
                  onChanged: (IconData? newValue) {
                    setState(() {
                      _selectedApplianceIcon = newValue;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: Icons.lightbulb_outline,
                      child: Icon(Icons.lightbulb_outline),
                    ),
                    DropdownMenuItem(
                      value: Icons.air,
                      child: Icon(Icons.air),
                    ),
                    DropdownMenuItem(
                      value: Icons.tv,
                      child: Icon(Icons.tv),
                    ),
                    DropdownMenuItem(
                      value: Icons.kitchen,
                      child: Icon(Icons.kitchen),
                    ),
                    // Add more icons as needed
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 212, 28, 28)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_applianceNameController.text.isNotEmpty &&
                    _selectedApplianceIcon != null) {
                  // Create a map with the updated appliance data
                  Map<String, dynamic> updatedApplianceData = {
                    'icon': _selectedApplianceIcon?.codePoint,
                    'name': _applianceNameController.text,
                    'deviceNumber': appliance[
                        'deviceNumber'], // Include updated device number
                  };

                  try {
                    // Update appliance data in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('registered_appliances')
                        .doc(applianceDocId)
                        .update(updatedApplianceData);

                    // Update the _appliances list
                    setState(() {
                      _appliances[index] = {
                        ..._appliances[index],
                        ...updatedApplianceData,
                      };
                    });

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Appliance updated successfully!',
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
                    print('Error updating appliance: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red), // Error icon
                            SizedBox(width: 8),
                            Text(
                              'Failed to update appliance.',
                              style: TextStyle(
                                color: Colors.white, // White text
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red, // Red background
                      ),
                    );
                  } finally {
                    // Clear the controllers and selected icon
                    _applianceNameController.clear();
                    _selectedApplianceIcon = null;
                    Navigator.pop(context); // Close the dialog
                  }
                } else {
                  // Show an error message if name or icon is not selected
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name and select an icon.'),
                    ),
                  );
                }
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

  // Function to show a confirmation dialog before removing an appliance
  Future<void> _showRemoveConfirmationDialog(int index) async {
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
                final appliance = _appliances[index];
                final applianceDocId = appliance['docId'];

                try {
                  // Remove appliance data from Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('registered_appliances')
                      .doc(applianceDocId)
                      .delete();

                  // Update the _appliances list
                  setState(() {
                    _appliances.removeAt(index);
                  });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: Container(
        color: Color.fromARGB(255, 243, 250, 244),
        child: _appliances.isEmpty
            ? const Center(
                child: Text('No appliances set up yet.'),
              )
            : ListView.builder(
                itemCount: _appliances.length,
                itemBuilder: (context, index) {
                  final appliance = _appliances[index];
                  final applianceDocId = appliance['docId'];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 223, 236, 219),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Column for Appliance Info
                          Row(
                            // Changed from Column to Row
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Appliance Icon
                              Icon(
                                IconData(appliance['icon'] ?? 0,
                                    fontFamily: 'MaterialIcons'),
                                size: 40,
                                color: const Color.fromARGB(255, 72, 100, 68),
                              ),
                              const SizedBox(width: 16), // Added spacing
                              // Wi-Fi Icon
                              Icon(
                                Icons.wifi,
                                size: 24,
                                color:
                                    _isApplianceOn ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 16), // Added spacing
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appliance['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    '${appliance['deviceNumber']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  // Constrained Runtime Text
                                  SizedBox(
                                    width: 120, // Adjust width as needed
                                    child: Text(
                                      '$_runtimeHours\h $_runtimeMinutes\m $_runtimeSeconds\s', // Remove spaces and use \ before units
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  // Status Text
                                  Text(
                                    _isApplianceOn
                                        ? 'Device Turned On'
                                        : 'Device Turned Off',
                                    style: TextStyle(
                                      color: _isApplianceOn
                                          ? Colors.green[700]
                                          : Colors.red,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Column for Toggle, Edit, Delete, and Status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Toggle Switch and Status Row
                              Row(
                                children: [
                                  // Toggle Switch
                                  Switch(
                                    value: _isApplianceOn,
                                    onChanged: (value) {
                                      setState(() {
                                        _isApplianceOn = value;
                                        _databaseRef.update(
                                            {'applianceState': _isApplianceOn});
                                      });
                                    },
                                    activeTrackColor: Colors.green[700],
                                    activeColor: Colors.green[900],
                                    inactiveTrackColor: Colors.grey[400],
                                    inactiveThumbColor: Colors.grey[300],
                                  ),
                                  const SizedBox(width: 8), // Added spacing
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Edit and Delete Buttons
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editAppliance(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _showRemoveConfirmationDialog(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Device Button
            SizedBox(
              width: MediaQuery.of(context).size.width * 1 / 2,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to SetupApplianceScreen when the button is pressed
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
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 12),
                    Text('Add an Appliance'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
