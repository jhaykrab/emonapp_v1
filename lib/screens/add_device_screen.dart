import 'package:flutter/material.dart';
import 'package:Emon/models/device_model.dart'; // Import the unified Device model

class DeviceConfigurationScreen extends StatefulWidget {
  const DeviceConfigurationScreen({super.key});

  @override
  _DeviceConfigurationScreenState createState() =>
      _DeviceConfigurationScreenState();
}

class _DeviceConfigurationScreenState extends State<DeviceConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceNameController = TextEditingController();
  final List<IconData> _availableIcons = [
    Icons.computer,
    Icons.speaker,
    Icons.lightbulb,
  ];
  IconData? _selectedIcon;
  final FocusNode _deviceNameFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 72, 100, 68),
          onPressed: () => Navigator.pop(context), // Simplified navigation
        ),
        backgroundColor: const Color(0xFFf5f5f5),
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      "Configure Your Device",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(255, 72, 100, 68),
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(height: 32),
                    Image.asset(
                      'assets/staticimgs/internet_connection.png',
                      height: 185.0,
                      width: 185.0,
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 8.0),
                      child: SizedBox(
                        width: 275,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _deviceNameController,
                                focusNode: _deviceNameFocusNode,
                                cursorColor:
                                    const Color.fromARGB(255, 54, 83, 56),
                                decoration: InputDecoration(
                                  labelText: 'Device Name',
                                  labelStyle: TextStyle(
                                    fontSize: 13,
                                    color: _deviceNameFocusNode.hasFocus
                                        ? const Color.fromARGB(255, 54, 83, 56)
                                        : const Color.fromARGB(255, 6, 17, 8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 16.0,
                                  ),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 54, 83, 56),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a device name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                                width:
                                    8.0), // Space between text field and dropdown
                            DropdownButton<IconData>(
                              value: _selectedIcon,
                              hint: const Icon(Icons.devices),
                              onChanged: (IconData? newValue) {
                                setState(() {
                                  _selectedIcon = newValue;
                                });
                              },
                              items: _availableIcons.map((IconData icon) {
                                return DropdownMenuItem<IconData>(
                                  value: icon,
                                  child: Icon(icon),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 275,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Device newDevice = Device(
                              name: _deviceNameController.text,
                              icon: _selectedIcon ?? Icons.devices,
                            );
                            Navigator.pop(context,
                                newDevice); // Pass the new device to the previous screen
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 54, 83, 56),
                          padding: const EdgeInsets.symmetric(
                              vertical: 17, horizontal: 80),
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
                          'Connect',
                          style: TextStyle(
                            color: Color(0xFFe8f5e9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
