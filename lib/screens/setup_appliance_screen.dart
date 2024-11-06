import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SetupApplianceScreen extends StatefulWidget {
  static const String routeName = '/setupAppliance';

  @override
  State<SetupApplianceScreen> createState() => _SetupApplianceScreenState();
}

class _SetupApplianceScreenState extends State<SetupApplianceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _applianceNameController = TextEditingController();
  final _maxUsageLimitController = TextEditingController();

  final List<IconData> _applianceIcons = [
    Icons.lightbulb_outline,
    Icons.air,
    Icons.tv,
    Icons.kitchen,
  ];

  IconData? _selectedApplianceIcon;
  String? _selectedTimeUnit;
  bool _screenOpened = false;
  int _deviceCount = 1;

  MobileScannerController cameraController = MobileScannerController();
  final FocusNode _applianceNameFocusNode = FocusNode();
  final FocusNode _maxUsageLimitFocusNode = FocusNode();

  final List<String> _timeUnits = ['hrs', 'min', 'sec'];

  @override
  void initState() {
    super.initState();
    _fetchDeviceCount();
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

  void _foundBarcode(BarcodeCapture capture) {
    if (!_screenOpened && capture.barcodes.isNotEmpty) {
      final String code = capture.barcodes.first.rawValue ?? "Unknown Code";
      _screenOpened = true;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Scanned Code"),
          content: Text(code),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _screenOpened = false;
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveApplianceData() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        if (_selectedApplianceIcon == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please choose an icon.')),
          );
          return;
        }

        if (_selectedTimeUnit == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Please set a time unit for Max Usage Limit.')),
          );
          return;
        }

        Map<String, dynamic> applianceData = {
          'icon': _selectedApplianceIcon?.codePoint,
          'name': _applianceNameController.text,
          'maxUsageLimit': int.tryParse(_maxUsageLimitController.text) ?? 0,
          'unit': _selectedTimeUnit,
          'isOn': false,
          'isRunning': false,
          'deviceNumber': 'Device $_deviceCount',
          'applianceType': _getSelectedApplianceType(),
        };

        try {
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('registered_appliances')
              .add(applianceData);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${_applianceNameController.text} has been set successfully!')),
          );
          Navigator.pushReplacementNamed(context, '/applianceList');
        } catch (e) {
          print('Error saving appliance data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save appliance data.')),
          );
        }
      } else {
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

  String _getSelectedApplianceType() {
    if (_selectedApplianceIcon == Icons.lightbulb_outline) {
      return 'lightbulb';
    } else if (_selectedApplianceIcon == Icons.air) {
      return 'fan';
    } else if (_selectedApplianceIcon == Icons.tv) {
      return 'tv';
    } else if (_selectedApplianceIcon == Icons.kitchen) {
      return 'refrigerator';
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Appliance'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const Text("Let's Set Up Your Appliance!"),
                const SizedBox(height: 10),

                // QR Code Scanner
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green.shade800,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: (barcode) => _foundBarcode(barcode),
                  ),
                ),

                const SizedBox(height: 16),

                // Appliance Name Field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
                  child: TextFormField(
                    controller: _applianceNameController,
                    focusNode: _applianceNameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Appliance Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an appliance name';
                      }
                      return null;
                    },
                  ),
                ),

                // Icon Selector
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
                  child: DropdownButtonFormField<IconData>(
                    value: _selectedApplianceIcon,
                    items: _applianceIcons.map((icon) {
                      return DropdownMenuItem(
                        value: icon,
                        child: Icon(icon),
                      );
                    }).toList(),
                    onChanged: (newIcon) {
                      setState(() {
                        _selectedApplianceIcon = newIcon;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Select Appliance Icon',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Max Usage Limit
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maxUsageLimitController,
                          focusNode: _maxUsageLimitFocusNode,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Max Usage Limit',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a max usage limit';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedTimeUnit,
                        items: _timeUnits.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTimeUnit = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _saveApplianceData,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _applianceNameController.dispose();
    _maxUsageLimitController.dispose();
    _applianceNameFocusNode.dispose();
    _maxUsageLimitFocusNode.dispose();
    super.dispose();
  }
}
