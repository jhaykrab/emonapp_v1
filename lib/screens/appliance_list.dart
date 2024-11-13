// appliance_list.dart
import 'package:flutter/material.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:provider/provider.dart';
import 'package:Emon/providers/appliance_provider.dart'; // Import your appliance provider
import 'package:Emon/models/appliance.dart';
import 'package:Emon/constants.dart'; // Import your constants file

class ApplianceListScreen extends StatefulWidget {
  static const String routeName = '/applianceList';

  const ApplianceListScreen({super.key});

  @override
  State<ApplianceListScreen> createState() => _ApplianceListScreenState();
}

class _ApplianceListScreenState extends State<ApplianceListScreen> {
  int _selectedIndex = 1;
  User? _user;
  String _userName = '';
  UserData? _userData;

  final DatabaseService _dbService = DatabaseService();

  // List to store appliance data fetched from Firestore
  List<Map<String, dynamic>> _appliances = [];
  bool _isLoading = true;

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

  Future<void> _fetchApplianceData() async {
    setState(() {
      _isLoading = true; // Set loading flag to true before fetching data
    });

    if (_user != null) {
      try {
        _appliances = await _dbService.getApplianceData(_user!.uid);

        // Initialize the ApplianceProvider with fetched data
        Provider.of<ApplianceProvider>(context, listen: false)
            .setAppliances(_appliances.map((applianceData) {
          return Appliance(
            name: applianceData['applianceName'] ?? '',
            icon: applianceIcons[applianceData['applianceType']] ??
                Icons.device_unknown,
            energy: (applianceData['energy'] ?? 0.0).toDouble(),
            voltage: (applianceData['voltage'] ?? 0.0).toDouble(),
            current: (applianceData['current'] ?? 0.0).toDouble(),
            power: (applianceData['power'] ?? 0.0).toDouble(),
            runtimehr: (applianceData['runtimehr'] ?? 0).toInt(),
            runtimemin: (applianceData['runtimemin'] ?? 0).toInt(),
            runtimesec: (applianceData['runtimesec'] ?? 0).toInt(),
            isApplianceOn: applianceData['isOn'] ?? false,
            documentId: applianceData['docId'] ?? '',
            serialNumber: applianceData['deviceSerialNumber'] ?? '',
            onToggleChanged: (value) {}, // You can leave this empty for now
            dbPath: _getDbPath(applianceData['deviceSerialNumber'] ?? ''),
          );
        }).toList());
      } catch (e) {
        print('Error fetching appliance data: $e');
        _appliances = []; // Set to empty list on error
        // You can also show an error message to the user here
      } finally {
        if (mounted) {
          setState(() {
            _isLoading =
                false; // Set loading flag to false after fetching data or handling errors
          });
        }
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
                  items: applianceIcons.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.value,
                      child: Icon(entry.value),
                    );
                  }).toList(),
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
                    'applianceType': applianceIcons.keys.firstWhere(
                        (k) => applianceIcons[k] == _selectedApplianceIcon),
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

  // Controllers for editing appliance name and icon
  final TextEditingController _editNameController = TextEditingController();
  IconData? _selectedEditIcon;

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
                // Call the update function
                _updateAppliance(appliance, index);
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

  // Function to update the appliance
  Future<void> _updateAppliance(Appliance appliance, int index) async {
    final applianceProvider =
        Provider.of<ApplianceProvider>(context, listen: false);

    // Update the appliance in the provider
    applianceProvider.editAppliance(
      appliance,
      _editNameController.text,
      _selectedEditIcon!,
      applianceIcons,
    );

    // Clear the controllers
    _editNameController.clear();
    _selectedEditIcon = null;
  }

  // Function to show a confirmation dialog before removing an appliance
  Future<void> _showRemoveConfirmationDialog(Appliance appliance) async {
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

  // Function to build the container for ApplianceListScreen
  Widget _buildApplianceListContainer(Widget child) {
    return Container(
      width: MediaQuery.of(context).size.width *
          0.7, // Reduced container width (70%)
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
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

  @override
  Widget build(BuildContext context) {
    const int maxNameLength = 15;
    final applianceProvider = Provider.of<ApplianceProvider>(context);
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: Center(
        // Wrap the Container with Center
        child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: _isLoading // Check if data is still loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 54, 83,
                            56)), // Show loading indicator with dark green color
                  )
                : applianceProvider.appliances
                        .isEmpty // Check if the list is empty after loading
                    ? const Center(
                        child: Text('No appliances set up yet.'),
                      )
                    : ListView.builder(
                        itemCount: applianceProvider.appliances.length,
                        itemBuilder: (context, index) {
                          final appliance = applianceProvider.appliances[index];

                          // Accessing data from the 'appliance' map
                          final applianceDocId =
                              appliance.documentId ?? 'Unknown';
                          final applianceName = appliance.name ??
                              'Unnamed Appliance'; // Fetching applianceName
                          final applianceType = appliance.icon;
                          final deviceSerialNumber =
                              appliance.serialNumber ?? 'N/A';

                          // Determine the Realtime Database path based on serial number
                          String dbPath = _getDbPath(deviceSerialNumber);

                          return StreamBuilder<DatabaseEvent>(
                            stream:
                                FirebaseDatabase.instance.ref(dbPath).onValue,
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.snapshot.value != null) {
                                final data = snapshot.data!.snapshot.value
                                    as Map<dynamic, dynamic>;

                                int runtimeHours = data['runtimehr'] ?? 0;
                                int runtimeMinutes = data['runtimemin'] ?? 0;
                                int runtimeSeconds = data['runtimesec'] ?? 0;
                                bool isApplianceOn =
                                    data['applianceState'] ?? false;

                                return _buildApplianceListContainer(
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            applianceType ??
                                                Icons.device_unknown,
                                            size: 32,
                                            color: const Color.fromARGB(
                                                255, 72, 100, 68),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.wifi,
                                            size: 18,
                                            color: isApplianceOn
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              MouseRegion(
                                                onEnter: (_) => setState(() {}),
                                                onExit: (_) => setState(() {}),
                                                child: Tooltip(
                                                  message: applianceName,
                                                  preferBelow: false,
                                                  child: Text(
                                                    applianceName.length >
                                                            maxNameLength
                                                        ? '${applianceName.substring(0, maxNameLength)}...'
                                                        : applianceName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'Serial No: $deviceSerialNumber',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 6),
                                              // Sensor readings
                                              Text(
                                                'Energy: ${data['energy'].toStringAsFixed(2)} kWh',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              Text(
                                                'Voltage: ${data['voltage'].toStringAsFixed(1)} V',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              Text(
                                                'Current: ${data['current'].toStringAsFixed(2)} A',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              Text(
                                                'Power: ${data['power'].toStringAsFixed(2)} W',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              // Display runtime
                                              Text(
                                                'Runtime: $runtimeHours hrs $runtimeMinutes mins $runtimeSeconds secs',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              Transform.scale(
                                                scale: 0.75,
                                                child: Switch(
                                                  value: isApplianceOn,
                                                  onChanged: (value) async {
                                                    await applianceProvider
                                                        .toggleAppliance(
                                                            appliance, value);
                                                  },
                                                  activeTrackColor:
                                                      Colors.green[700],
                                                  activeColor:
                                                      Colors.green[900],
                                                  inactiveTrackColor:
                                                      Colors.grey[400],
                                                  inactiveThumbColor:
                                                      Colors.grey[300],
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
                                                onPressed: () =>
                                                    _showEditDialog(
                                                        appliance, index),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _showRemoveConfirmationDialog(
                                                        appliance),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return _buildApplianceListContainer(
                                  Text('Error: ${snapshot.error}'),
                                );
                              } else {
                                return _buildApplianceListContainer(
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      )),
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

  // Function to determine the Realtime Database path based on serial number
  String _getDbPath(String serialNumber) {
    switch (serialNumber) {
      case '11032401':
        return 'SensorReadings';
      case '11032402':
        return 'SensorReadings_2';
      case '11032403':
        return 'SensorReadings_3';
      default:
        return 'SensorReadings'; // Default path
    }
  }
}
