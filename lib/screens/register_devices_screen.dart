import 'package:Emon/models/device_model.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/add_device_screen.dart';
import 'package:Emon/screens/setup_appliance_screen.dart'; // Import SetupApplianceScreen

class DevicesScreen extends StatefulWidget {
  static const String routeName = '/devices';

  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Device> devices = [];
  String? deviceName; // Variable to store the device name

  @override
  void initState() {
    super.initState();
    // Remove any existing SnackBars that might have been passed from previous screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Device) {
        _addDevice(args);
      }
    });
  }

  void _addDevice(Device newDevice) {
    setState(() {
      devices.add(newDevice);
    });
  }

  void _editDevice(int index, Device editedDevice) {
    setState(() {
      devices[index] = editedDevice;
    });
  }

  // Method to open the edit dialog
  Future<void> _showEditDialog(int index) async {
    final device = devices[index];
    final nameController = TextEditingController(text: device.name);
    IconData? selectedIcon = device.icon;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Device',
            style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
          ),
          content: SingleChildScrollView(
            // Wrap content with SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prevent dialog from overflowing
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    labelStyle: TextStyle(
                        color: Color.fromARGB(
                            255, 22, 22, 22)), // Set label color to black
                  ),
                  style: const TextStyle(
                      color: Color.fromARGB(
                          255, 54, 83, 56)), // Set text field text color
                ),
                const SizedBox(height: 16.0),
                DropdownButton<IconData>(
                  value: selectedIcon,
                  hint: const Text(
                    'Select Icon',
                    style: TextStyle(
                        color: Color.fromARGB(
                            255, 54, 83, 56)), // Set hint text color
                  ),
                  onChanged: (IconData? newValue) {
                    // Update the selected icon within the dialog
                    setState(() {
                      selectedIcon = newValue;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: Icons.computer,
                      child: Icon(Icons.computer),
                    ),
                    DropdownMenuItem(
                      value: Icons.speaker,
                      child: Icon(Icons.speaker),
                    ),
                    DropdownMenuItem(
                      value: Icons.lightbulb,
                      child: Icon(Icons.lightbulb),
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
                'CANCEL',
                style: TextStyle(color: Color.fromARGB(255, 114, 18, 18)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, nameController.text);
                // Update the device with the new icon
                _editDevice(
                  index,
                  Device(name: nameController.text, icon: selectedIcon!),
                );
              },
              child: const Text(
                'SAVE',
                style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRemoveConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Remove Device',
            style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to remove this device?',
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
              onPressed: () {
                setState(() {
                  devices.removeAt(index);
                });
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
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        title: const Text('Registered Devices', style: TextStyle(fontSize: 18)),
        foregroundColor: const Color(0xFFf5f5f5),
        backgroundColor: const Color.fromARGB(255, 54, 83, 56),
        elevation: 6.0,
        shadowColor: const Color.fromARGB(255, 27, 38, 28).withOpacity(0.8),
      ),
      body: Column(
        children: [
          // Display the device name in a green container
          if (deviceName != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Device Name: $deviceName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),

          const SizedBox(height: 40.0),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: const Color.fromARGB(255, 177, 206, 173),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 41, 58, 44)
                                .withOpacity(0.2),
                            blurRadius: 2.0,
                            spreadRadius: 2.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(device.icon,
                                  size: 35.0,
                                  color:
                                      const Color.fromARGB(255, 72, 100, 68)),
                              const SizedBox(width: 8.0),
                              Text(device.name,
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 29, 29, 29),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _showRemoveConfirmationDialog(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ));
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add Device Button
            SizedBox(
              width: MediaQuery.of(context).size.width *
                  1 /
                  2, // Button width is 1/3 of screen width
              child: ElevatedButton(
                onPressed: () async {
                  final newDevice = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeviceConfigurationScreen(),
                    ),
                  );

                  if (newDevice != null && newDevice is Device) {
                    _addDevice(newDevice);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                  foregroundColor: const Color(0xFFe8f5e9),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 16), // Reduced horizontal padding further
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
                    SizedBox(width: 8.0), // Space between icon and text
                    Text('Add Device'),
                    Icon(Icons.add),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16.0), // Spacing between buttons

            // Continue Button (Transparent with Green Outline)
            SizedBox(
              width: MediaQuery.of(context).size.width * 1 / 2,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetupApplianceScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color.fromARGB(255, 54, 83, 56), // Green text color
                  side: const BorderSide(
                      color: Color.fromARGB(255, 54, 83, 56),
                      width: 2), // Green border
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 16), // Reduced horizontal padding further
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
                    SizedBox(width: 8.0), // Space between text and icon
                    Text('Continue'),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50.0),
          ],
        ),
      ),
    );
  }
}
