import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/constants.dart';

class SetupApplianceScreen extends StatefulWidget {
  static const String routeName = '/setupAppliance';

  const SetupApplianceScreen({Key? key})
      : super(key: key); // Added const constructor

  @override
  State<SetupApplianceScreen> createState() => _SetupApplianceScreenState();
}

class _SetupApplianceScreenState extends State<SetupApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _applianceNameController = TextEditingController();
  final _deviceSerialNumberController = TextEditingController();
  final _maxUsageLimitController = TextEditingController();

  final List<IconData> _applianceIcons = [
    Icons.lightbulb_outline,
    Icons.air,
    Icons.tv,
    Icons.kitchen,
  ];
  IconData? _selectedApplianceIcon;

  int _deviceCount = 1;
  final List<String> _timeUnits = ['hrs', 'min', 'sec'];
  String? _selectedTimeUnit = 'hrs'; // Initialize with a default value
  bool _isSerialNumberValid = false;
  bool _isDeviceFound = false;
  bool _areFieldsEnabled = false;

  final FocusNode _applianceNameFocusNode = FocusNode();
  final FocusNode _maxUsageLimitFocusNode = FocusNode();
  final FocusNode _deviceSerialNumberFocusNode = FocusNode();

  int _nextDbPathIndex = 0;
  List<String> _dbPaths = [
    'SensorReadings',
    'SensorReadings_2',
    'SensorReadings_3',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDeviceCount();
    _fetchNextDbPathIndex();
    _deviceSerialNumberController.addListener(_checkSerialNumber);
  }

  @override
  void dispose() {
    _deviceSerialNumberController.removeListener(_checkSerialNumber);
    _deviceSerialNumberController.dispose();
    _applianceNameController.dispose();
    _maxUsageLimitController.dispose();
    _applianceNameFocusNode.dispose();
    _maxUsageLimitFocusNode.dispose();
    _deviceSerialNumberFocusNode.dispose();

    super.dispose();
  }

  void _clearFields() {
    _applianceNameController.clear();
    _deviceSerialNumberController.clear();
    _maxUsageLimitController.clear();
    setState(() {
      _selectedApplianceIcon = null;
      _selectedTimeUnit = 'hrs';
      _isSerialNumberValid = false;
      _isDeviceFound = false;
      _areFieldsEnabled = false;
    });
  }

  void _checkSerialNumber() {
    setState(() {
      _isDeviceFound = false;
    });
  }

  Future<void> _searchSerialNumber() async {
    final serialNumber = _deviceSerialNumberController.text;

    if (serialNumber.isEmpty) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    bool isDeviceInUse = false;
    bool deviceFound = false;

    try {
      for (String path in _dbPaths) {
        final DataSnapshot snapshot = await dbRef.child(path).get();

        if (snapshot.value != null && snapshot.value is Map) {
          final Map<dynamic, dynamic> data =
              snapshot.value as Map<dynamic, dynamic>;

          if (data.containsKey('serialNumber') &&
              data['serialNumber'] == serialNumber) {
            deviceFound = true;
            if (data.containsKey('uid') && data['uid'] != null) {
              isDeviceInUse = true;
            }
            break;
          }
        }
      }

      setState(() {
        _isDeviceFound = !isDeviceInUse;
        _areFieldsEnabled = _isDeviceFound; //Simplified conditional
        _isSerialNumberValid =
            deviceFound; // Set to true if a device is found with/without uid
      });

      if (!deviceFound && serialNumber.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline_rounded,
                    color: Colors.white), // White wrong icon
                SizedBox(width: 8),
                Text('No device for that serial number yet!',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color.fromARGB(
                255, 255, 105, 97), // Lighter red background
            behavior: SnackBarBehavior.floating, // Modern snackbar behavior
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
            ),
            margin: const EdgeInsets.only(
                bottom: 20.0,
                left: 15.0,
                right: 15.0), // Add margin from the edges
          ),
        );
      } else if (isDeviceInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline_rounded,
                    color: Colors.white), // White wrong icon
                SizedBox(width: 8),
                Text('Device already in use!',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color.fromARGB(
                255, 255, 105, 97), // Lighter red background
            behavior: SnackBarBehavior.floating, // Modern snackbar behavior
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Rounded corners
            ),
            margin: const EdgeInsets.only(
                bottom: 20.0,
                left: 15.0,
                right: 15.0), // Add margin from the edges
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: Colors.white), // Filled check icon
                SizedBox(width: 8),
                Text('Device Available!',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor:
                const Color.fromARGB(255, 54, 83, 56), // Darker green
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: const EdgeInsets.only(
                bottom: 20.0, left: 15.0, right: 15.0), // Add margin
          ),
        );
      }
    } catch (e) {
      print('Error searching serial number: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error occurred while searching.'),
        ),
      );
    }
  }

  Future<void> _fetchDeviceCount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('registered_appliances')
            .get();

        setState(() {
          _deviceCount = snapshot.docs.length + 1;
          _nextDbPathIndex = (_deviceCount - 1) % _dbPaths.length;
        });
      } catch (e) {
        print('Error fetching device count: $e');
      }
    }
  }

  Future<void> _fetchNextDbPathIndex() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('registered_appliances')
            .get();

        setState(() {
          _nextDbPathIndex = snapshot.docs.length % _dbPaths.length;
        });
      } catch (e) {
        print('Error fetching next dbPath index: $e');
      }
    }
  }

  String? _selectedApplianceType;

  String _getSelectedApplianceType() {
    if (_selectedApplianceIcon == Icons.lightbulb_outline) {
      return 'lightbulb';
    } else if (_selectedApplianceIcon == Icons.air) {
      return 'fan';
    } else if (_selectedApplianceIcon == Icons.tv) {
      return 'tv';
    } else if (_selectedApplianceIcon == Icons.kitchen) {
      return 'refrigerator';
    } else {
      return 'unknown';
    }
  }

  Future<void> _saveApplianceData() async {
    if (_formKey.currentState!.validate() &&
        _isSerialNumberValid &&
        _selectedApplianceType != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          String applianceName = _applianceNameController.text;
          String deviceSerialNumber = _deviceSerialNumberController.text;
          int maxUsageLimit = int.parse(_maxUsageLimitController.text);
          String applianceType = _selectedApplianceType!;
          String dbPath = _dbPaths[_nextDbPathIndex];

          // Save the appliance data to Firestore
          DocumentReference docRef = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('registered_appliances')
              .add({
            'applianceName': applianceName,
            'deviceSerialNumber': deviceSerialNumber,
            'maxUsageLimit': maxUsageLimit,
            'selectedTimeUnit': _selectedTimeUnit ?? 'hrs',
            'applianceType': applianceType,
            'deviceNumber': _deviceCount,
            'dbPath': dbPath, // Add dbPath to Firestore
          });

          // --- Send UID to Realtime Database ---
          final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

          await dbRef.child('$dbPath/uid').set(user.uid);
          print('UID sent to Realtime Database path: $dbPath');

          _nextDbPathIndex = (_nextDbPathIndex + 1) % _dbPaths.length;

          _applianceNameController.clear();
          _deviceSerialNumberController.clear();
          _maxUsageLimitController.clear();
          setState(() {
            _selectedApplianceIcon = null;
            _selectedTimeUnit = null;
            _isSerialNumberValid = false;
          });
          _fetchDeviceCount();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                // Row for icon and text
                children: const [
                  Icon(Icons.check_circle,
                      color: const Color.fromARGB(255, 54, 83, 56)),
                  SizedBox(width: 8),
                  Text(
                    'Appliance saved successfully!',
                    style: TextStyle(
                        color: const Color.fromARGB(
                            255, 54, 83, 56)), // White text
                  ),
                ],
              ),
              backgroundColor:
                  const Color.fromARGB(255, 211, 243, 213), // Darker green
              behavior: SnackBarBehavior.floating, // Floating behavior
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0), // Rounded corners
              ),
              margin: const EdgeInsets.only(
                  bottom: 20.0, left: 15.0, right: 15.0), // Margins
              duration: const Duration(seconds: 2), //Optional duration
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
              context, ApplianceListScreen.routeName, (route) => false);
        } catch (e) {
          print('Error saving appliance data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error,
                      color: Color.fromARGB(255, 110, 36, 36)), // White icon
                  SizedBox(width: 8),
                  Text('Error saving appliance data.',
                      style:
                          TextStyle(color: Color.fromARGB(255, 110, 36, 36))),
                ],
              ),
              backgroundColor:
                  const Color.fromARGB(255, 243, 208, 206), // Lighter red
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields correctly.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 72, 100, 68),
          onPressed: () {
            Navigator.pop(context);
            _clearFields(); // Clear fields when navigating back
          },
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            fontFamily: 'Rubik',
            color: Color.fromARGB(255, 72, 100, 68),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 243, 250, 244),
        elevation: 0,
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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "Let's Set Up Your Appliance!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Logo
                  Image.asset(
                    'assets/staticimgs/tech-support-concept-illustration.png',
                    height: 200.0,
                    width: 200.0,
                  ),
                  const SizedBox(height: 20),

                  // Device Serial Number Input with message and disabling
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _deviceSerialNumberController,
                                  focusNode: _deviceSerialNumberFocusNode,
                                  enabled: !_isDeviceFound,
                                  cursorColor:
                                      const Color.fromARGB(255, 54, 83, 56),
                                  decoration: InputDecoration(
                                    labelText: 'Device Serial Number',
                                    labelStyle: TextStyle(
                                      fontSize: 13,
                                      color: _deviceSerialNumberFocusNode
                                              .hasFocus
                                          ? const Color.fromARGB(
                                              255, 54, 83, 56)
                                          : const Color.fromARGB(255, 6, 17, 8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isSerialNumberValid
                                            ? Colors.green
                                            : Colors.red,
                                        width: 2.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isSerialNumberValid
                                            ? Colors.green
                                            : Colors.red,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a device serial number';
                                    }
                                    if (value.length < 8 || value.length > 10) {
                                      return 'Serial number must be 8-10 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _isDeviceFound ? null : _searchSerialNumber,
                                icon: const Icon(Icons.search,
                                    color: Color.fromARGB(255, 54, 83, 56)),
                              ),
                              IconButton(
                                onPressed: () {
                                  print('Wi-Fi button pressed!');
                                },
                                icon: const Icon(Icons.wifi,
                                    color: Color.fromARGB(255, 54, 83, 56)),
                              ),
                            ],
                          ),
                          if (!_isDeviceFound &&
                              _deviceSerialNumberController.text.isNotEmpty)
                            ...[],
                        ],
                      ),
                    ),
                  ),

                  // Appliance Name and Icon Dropdown (Combined)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: AbsorbPointer(
                        // Disable this field initially
                        absorbing: !_isSerialNumberValid,
                        child: TextFormField(
                          controller: _applianceNameController,
                          focusNode: _applianceNameFocusNode,
                          cursorColor: const Color.fromARGB(255, 54, 83, 56),
                          decoration: InputDecoration(
                            labelText: 'Set Appliance Name',
                            labelStyle: TextStyle(
                              fontSize: 13,
                              color: _applianceNameFocusNode.hasFocus
                                  ? const Color.fromARGB(255, 54, 83, 56)
                                  : const Color.fromARGB(255, 6, 17, 8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.green.shade800),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color.fromARGB(255, 54, 83, 56),
                                width: 2.0,
                              ),
                            ),
                            suffixIcon: IntrinsicWidth(
                              // Use IntrinsicWidth for automatic sizing
                              child: DropdownButton<String>(
                                value: _selectedApplianceType,
                                hint: const Text(
                                  'select icon',
                                  style: TextStyle(
                                      fontSize: 14), // Decreased font size
                                ), // Add a hint
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedApplianceType = newValue;
                                  });
                                },
                                items: applianceIcons.keys.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: SizedBox(
                                      // Add SizedBox to DropdownMenuItem
                                      width: 80, // Adjust width as needed
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(applianceIcons[type]),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            // Wrap text with Flexible
                                            child: Text(
                                              type,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow
                                                  .ellipsis, // Handle overflow
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an appliance name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),

                  // Max Usage Limit and Time Unit Dropdown (Combined)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: AbsorbPointer(
                        // Disable this field initially
                        absorbing: !_isSerialNumberValid,
                        child: IntrinsicHeight(
                          child: TextFormField(
                            focusNode: _maxUsageLimitFocusNode,
                            controller: _maxUsageLimitController,
                            cursorColor: const Color.fromARGB(255, 54, 83, 56),
                            decoration: InputDecoration(
                              labelText: 'Set Max Usage Limit',
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: _maxUsageLimitFocusNode.hasFocus
                                    ? const Color.fromARGB(255, 54, 83, 56)
                                    : const Color.fromARGB(255, 6, 17, 8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 16.0),
                              border: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.green.shade800),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 54, 83, 56),
                                  width: 2.0,
                                ),
                              ),
                              suffixIcon: SizedBox(
                                // Wrap DropdownButtonFormField with SizedBox
                                width: 55, // Adjust width as needed
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTimeUnit,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedTimeUnit = newValue!;
                                    });
                                  },
                                  items: _timeUnits.map((String unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Color.fromARGB(
                                                  255, 117, 116, 116))),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ], // Allow only digits
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a max usage limit';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save and Cancel Buttons
                  Column(
                    children: [
                      SizedBox(
                        // SizedBox for width constraints
                        width: 280, // Set your desired width here
                        child: ElevatedButton(
                          onPressed: _isSerialNumberValid && _isDeviceFound
                              ? _saveApplianceData
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 54, 83, 56),
                            padding: const EdgeInsets.symmetric(
                                vertical: 17), // Remove horizontal padding
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: const Text('Save',
                              style: TextStyle(color: Color(0xFFe8f5e9))),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        // SizedBox for width constraints
                        width: 280, // Set your desired width here
                        child: ElevatedButton(
                          onPressed: _clearFields,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // White background
                            foregroundColor: const Color.fromARGB(
                                255, 72, 100, 68), // Dark red text
                            side: const BorderSide(
                                color: Color.fromARGB(
                                    255, 72, 100, 68)), // Dark red border
                            padding: const EdgeInsets.symmetric(
                                vertical: 17), // Remove horizontal padding
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
                              'Cancel'), // No need to specify text color (foregroundColor handles it)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
