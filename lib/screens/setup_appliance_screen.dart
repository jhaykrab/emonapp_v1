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

  @override
  void initState() {
    super.initState();
    _fetchDeviceCount();
  }

  Future<void> _searchSerialNumber() async {
    final serialNumber = _deviceSerialNumberController.text;

    if (serialNumber.isEmpty) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
    Set<String> foundSerialNumbers = {};
    List<String> paths = [
      'SensorReadings/serialNumber',
      'SensorReadings_2/serialNumber',
      'SensorReadings_3/serialNumber',
    ];

    try {
      for (String path in paths) {
        final DataSnapshot snapshot = await dbRef.child(path).get();

        // Directly compare the snapshot value to the serialNumber
        if (snapshot.value != null &&
            snapshot.value.toString() == serialNumber) {
          foundSerialNumbers.add(serialNumber);
        }
      }

      setState(() {
        _isSerialNumberValid = foundSerialNumbers.isNotEmpty;
        _areFieldsEnabled =
            _isSerialNumberValid; // Enable fields if serial number is valid
      });

      // Provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (_isSerialNumberValid) ...[
                const Icon(Icons.check_circle, color: Colors.green),
              ] else ...[
                const Icon(Icons.cancel, color: Colors.red), // Wrong icon
              ],
              const SizedBox(width: 8),
              Text(
                _isSerialNumberValid
                    ? 'Device serial number found!'
                    : 'Device serial number not found!',
                style: TextStyle(
                  color: _isSerialNumberValid ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 243, 250, 244),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error searching serial number: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error occurred while searching.'),
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
        });
      } catch (e) {
        print('Error fetching device count: $e');
      }
    }
  }

  String _getSelectedApplianceType() {
    if (_selectedApplianceIcon == Icons.lightbulb_outline) return 'lightbulb';
    if (_selectedApplianceIcon == Icons.air) return 'fan';
    if (_selectedApplianceIcon == Icons.tv) return 'tv';
    if (_selectedApplianceIcon == Icons.kitchen) return 'refrigerator';
    return 'unknown';
  }

  Future<void> _saveApplianceData() async {
    if (_formKey.currentState!.validate() && _isSerialNumberValid) {
      // Form is valid, proceed with saving data
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Get the data from the form fields
          String applianceName = _applianceNameController.text;
          String deviceSerialNumber = _deviceSerialNumberController.text;
          int maxUsageLimit = int.parse(_maxUsageLimitController.text);
          String applianceType = _getSelectedApplianceType();

          // Save the appliance data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('registered_appliances')
              .add({
            'applianceName': applianceName,
            'deviceSerialNumber': deviceSerialNumber,
            'maxUsageLimit': maxUsageLimit,
            'selectedTimeUnit': _selectedTimeUnit ?? 'hrs', // Default to 'hrs'
            'applianceType': applianceType,
            'deviceNumber': _deviceCount,
          });

          // Optionally, you can clear the form fields or navigate to another screen
          _applianceNameController.clear();
          _deviceSerialNumberController.clear();
          _maxUsageLimitController.clear();
          setState(() {
            _selectedApplianceIcon = null;
            _selectedTimeUnit = null;
            _isSerialNumberValid = false;
          });
          _fetchDeviceCount(); // Update device count

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appliance saved successfully!'),
            ),
          );

          // Navigate to the ApplianceListScreen
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
      // Form is not valid, show an error message or take appropriate action
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
