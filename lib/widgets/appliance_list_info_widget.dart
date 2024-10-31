import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Import for Firebase Realtime Database

class ApplianceListInfoWidget extends StatefulWidget {
  const ApplianceListInfoWidget({Key? key}) : super(key: key);

  @override
  State<ApplianceListInfoWidget> createState() =>
      _ApplianceListInfoWidgetState();
}

class _ApplianceListInfoWidgetState extends State<ApplianceListInfoWidget> {
  // Firebase Realtime Database reference
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('devices');

  // Sample data for demonstration (replace with your actual data)
  final List<Map<String, dynamic>> appliances = [
    {
      'name': 'Smart Bulb 1',
      'icon': Icons.lightbulb_outline,
      'deviceNumber': '1', // Unique identifier for the device in Firebase
      'isRunning': false, // Initially, the device is off
      'isOn': false, // Initially, the switch is off
    },
    // Add more appliance data here
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Text(
                "Registered Appliances",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 72, 100, 68),
                ),
              ),
            ],
          ),
        ),

        // Appliance List
        Expanded(
          child: ListView.builder(
            itemCount: appliances.length,
            itemBuilder: (context, index) {
              final appliance = appliances[index];
              return Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 223, 236, 219),
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        appliance['icon'],
                        size: 40,
                        color: const Color.fromARGB(255, 72, 100, 68),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.wifi,
                        size: 24,
                        color: appliance['isOn'] ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                  title: Text(
                    appliance['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Device ${appliance['deviceNumber']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appliance['isRunning'] ? 'Running' : 'Not Running',
                        style: TextStyle(
                          color: appliance['isRunning']
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Realtime Switch (from DeviceInfoWidget)
                      StreamBuilder<DatabaseEvent>(
                        stream: _databaseReference
                            .child(appliance['deviceNumber'])
                            .child('isOn')
                            .onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.snapshot.value != null) {
                            bool isOn = snapshot.data!.snapshot.value as bool;
                            return Switch(
                              value: isOn,
                              onChanged: (value) {
                                _databaseReference
                                    .child(appliance['deviceNumber'])
                                    .update({'isOn': value});
                                setState(() {
                                  appliance['isOn'] = value;
                                  appliance['isRunning'] = value;
                                });
                                // TODO: Add logic to communicate the switch state to the actual device
                              },
                              activeTrackColor: Colors.green[700],
                              activeColor: Colors.green[900],
                              inactiveTrackColor: Colors.grey[400],
                              inactiveThumbColor: Colors.grey[300],
                            );
                          } else {
                            return SizedBox(
                              width: 20, // Adjust the width as needed
                              height: 20, // Adjust the height as needed
                              child: CircularProgressIndicator(
                                strokeWidth: 3, // Adjust the stroke width
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color.fromARGB(
                                      255, 72, 100, 68), // Dark green color
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
