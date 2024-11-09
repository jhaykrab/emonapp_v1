import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class SetupApplianceScreen extends StatefulWidget {
  static const String routeName = '/setupAppliance';

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
  String? _selectedTimeUnit;
  bool _isSerialNumberValid = false;
  bool _areFieldsEnabled = false; // Flag to control field enabling

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
  }

  Future<void> _searchSerialNumber() async {
    final serialNumber = _deviceSerialNumberController.text;

    if (serialNumber.isEmpty) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    bool isDeviceInUse = false;
    try {
      for (String path in _dbPaths) {
        final DataSnapshot snapshot = await dbRef.child(path).get();

        if (snapshot.value != null && snapshot.value is Map) {
          final Map<dynamic, dynamic> data =
              snapshot.value as Map<dynamic, dynamic>;

          if (data.containsKey('serialNumber') &&
              data['serialNumber'] == serialNumber &&
              data.containsKey('uid') &&
              data['uid'] != null) {
            isDeviceInUse = true;
            break;
          }
        }
      }

      setState(() {
        _isSerialNumberValid = !isDeviceInUse;
        _areFieldsEnabled = _isSerialNumberValid;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (_isSerialNumberValid) ...[
                const Icon(Icons.check_circle, color: Colors.green),
              ] else ...[
                const Icon(Icons.cancel, color: Colors.red),
              ],
              const SizedBox(width: 8),
              Text(
                _isSerialNumberValid
                    ? 'Device serial number found!'
                    : 'Device already in use!',
                style: TextStyle(
                  color: _isSerialNumberValid ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 243, 250, 244),
          duration: const Duration(seconds: 2),
        ),
      );
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
          // Update _nextDbPathIndex based on the current device count
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
    if (_formKey.currentState!.validate() && _isSerialNumberValid) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          String applianceName = _applianceNameController.text;
          String deviceSerialNumber = _deviceSerialNumberController.text;
          int maxUsageLimit = int.parse(_maxUsageLimitController.text);
          String applianceType = _getSelectedApplianceType();
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
            const SnackBar(
              content: Text('Appliance saved successfully!'),
            ),
          );

          Navigator.pushReplacementNamed(
              context, ApplianceListScreen.routeName);
        } catch (e) {
          print('Error saving appliance data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving appliance data.'),
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
          onPressed: () => Navigator.pop(context),
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
        backgroundColor: Color.fromARGB(255, 243, 250, 244),
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

                  // Device Serial Number Input
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _deviceSerialNumberController,
                              focusNode: _deviceSerialNumberFocusNode,
                              cursorColor:
                                  const Color.fromARGB(255, 54, 83, 56),
                              decoration: InputDecoration(
                                labelText: 'Device Serial Number',
                                labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: _deviceSerialNumberFocusNode.hasFocus
                                      ? const Color.fromARGB(255, 54, 83, 56)
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
                            onPressed: _searchSerialNumber,
                            icon: const Icon(
                              Icons.search,
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Add your Wi-Fi scanning logic here later
                              print('Wi-Fi button pressed!');
                            },
                            icon: const Icon(
                              Icons.wifi,
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                          ),
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
                            suffixIcon: DropdownButton<IconData>(
                              value: _selectedApplianceIcon,
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedApplianceIcon = newValue;
                                });
                              },
                              items: _applianceIcons.map((icon) {
                                return DropdownMenuItem(
                                  value: icon,
                                  child: Icon(icon), // Display Icon widget
                                );
                              }).toList(),
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
                                width: 60, // Adjust width as needed
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTimeUnit,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedTimeUnit = newValue!;
                                    });
                                  },
                                  items: _timeUnits
                                      .map((unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(unit),
                                          ))
                                      .toList(),
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

                  // Save Button
                  ElevatedButton(
                    onPressed:
                        _isSerialNumberValid // Enable button only if serial number is valid
                            ? _saveApplianceData
                            : null, // Call the save function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 123,
                      ),
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
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFe8f5e9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
