import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:wifi_scan/wifi_scan.dart'; // Wi-Fi scanning
import 'package:flutter/services.dart';

class SetupApplianceScreen extends StatefulWidget {
  static const String routeName = '/setupAppliance';

  @override
  State<SetupApplianceScreen> createState() => _SetupApplianceScreenState();
}

class _SetupApplianceScreenState extends State<SetupApplianceScreen> {
  final _formKey = GlobalKey<FormState>();

  // TextEditingController for appliance name
  final _applianceNameController = TextEditingController();

  // List of IconData for appliance icons (using Icons class)
  final List<IconData> _applianceIcons = [
    Icons.lightbulb_outline,
    Icons.air, // Fan icon
    Icons.tv,
    Icons.kitchen, // Refrigerator icon
    // Add more icons from Icons class as needed
  ];
  IconData? _selectedApplianceIcon;

  @override
  void initState() {
    super.initState();
    _fetchDeviceCount(); // Fetch the initial device count from Firestore
  }

  int _deviceCount = 1;

  // List of String values for time units
  final List<String> _timeUnits = ['hrs', 'min', 'sec'];
  String? _selectedTimeUnit;

  // TextEditingController for max usage limit
  final _maxUsageLimitController = TextEditingController();

  // TextEditingController for device serial number
  final _deviceSerialNumberController = TextEditingController();

  // Focus nodes for text fields
  final FocusNode _applianceNameFocusNode = FocusNode();
  final FocusNode _maxUsageLimitFocusNode = FocusNode();
  final FocusNode _deviceSerialNumberFocusNode = FocusNode();

  Future<void> _saveApplianceData() async {
    if (_formKey.currentState!.validate()) {
      print("Form is valid!"); // Debugging: Check if validation passes

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        print("User UID: ${user.uid}"); // Debugging: Check if user is logged in

        // Access Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Input Validation
        if (_selectedApplianceIcon == null) {
          // Show error message for missing icon
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red), // Red warning icon
                  SizedBox(width: 8),
                  Text(
                    'Please choose an icon.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 114, 18, 18), // Dark red text
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent, // Transparent background
              elevation: 0, // No shadow
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red, width: 2), // Red outline
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return; // Stop execution if icon is not selected
        }
        SizedBox(height: 30);

        if (_selectedTimeUnit == null) {
          // Show error message for missing time unit
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning,
                      color: const Color.fromARGB(
                          255, 243, 121, 40)), // Red warning icon
                  SizedBox(width: 8),
                  Text(
                    'Please set a time unit for Max Usage Limit.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 114, 18, 18), // Dark red text
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent, // Transparent background
              elevation: 0, // No shadow
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red, width: 2), // Red outline
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          return; // Stop execution if time unit is not selected
        }

        SizedBox(height: 30);

        // Create a map with the appliance data
        Map<String, dynamic> applianceData = {
          'icon': _selectedApplianceIcon?.codePoint,
          'name': _applianceNameController.text,
          'maxUsageLimit': int.tryParse(_maxUsageLimitController.text) ??
              0, // Use int.tryParse for whole numbers
          'unit': _selectedTimeUnit,
          'isOn': false, // Initially, the appliance is off
          'isRunning': false, // Initially, the appliance is not running
          'deviceSerialNumber': _deviceSerialNumberController
              .text, // Add device serial number to data
          'applianceType': _getSelectedApplianceType(), // Add appliance type
        };

        try {
          // Add appliance data to Firestore under the user's UID in 'registered_appliances' subcollection
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('registered_appliances')
              .add(applianceData);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_applianceNameController.text} has been set successfully!',
                style: const TextStyle(
                  color: Color.fromARGB(255, 54, 83, 56),
                ),
              ),
              backgroundColor: const Color.fromARGB(255, 193, 223, 194),
            ),
          );

          // Navigate to ApplianceListScreen after successful save
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const ApplianceListScreen()),
          );
        } catch (e) {
          // Handle errors
          print(
              'Error saving appliance data: $e'); // Print the error to the console
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save appliance data.'),
            ),
          );
        }
      } else {
        // Handle the case where the user is not logged in
        print('User is not logged in!');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Not Logged In"),
            content: const Text("Please log in to save appliances."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  // Function to fetch the device count from Firestore
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
          _deviceCount = snapshot.docs.length +
              1; // Set _deviceCount based on existing appliances
        });
      } catch (e) {
        print('Error fetching device count: $e');
        // Handle the error appropriately, e.g., show an error message
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
      return 'unknown'; // Default or handle other cases
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 72, 100, 68),
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Make the text bold
            fontSize: 22,
            fontFamily: 'Rubik',
            color: Color.fromARGB(255, 72, 100, 68), // Dark green color
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
                                  borderSide:
                                      BorderSide(color: Colors.green.shade800),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 54, 83, 56),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ], // Allow only digits and limit to 10
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

                  // Max Usage Limit and Time Unit Dropdown (Combined)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
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

                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveApplianceData, // Call the save function
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
