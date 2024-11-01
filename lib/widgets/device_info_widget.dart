import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // Import math library for animation

import 'package:Emon/screens/add_device_screen.dart';

class DeviceInfoWidget extends StatefulWidget {
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimehr;
  final int runtimemin;
  final int runtimesec;
  final bool isApplianceOn;
  final ValueChanged<bool> onToggleChanged;

  const DeviceInfoWidget({
    Key? key,
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimehr,
    required this.runtimemin,
    required this.runtimesec,
    required this.isApplianceOn,
    required this.onToggleChanged,
  }) : super(key: key);

  @override
  _DeviceInfoWidgetState createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget>
    with SingleTickerProviderStateMixin {
  bool _showDeleteIcon = false; // Flag to control delete icon visibility
  late AnimationController _animationController; // Animation controller

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200), // Adjust shake duration
    );
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 450,
        padding: EdgeInsets.all(16.0),
        margin: EdgeInsets.only(top: 40.0), // Increased top margin
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 223, 236, 219),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date and Day of the Week
            Center(
              child: Text(
                DateFormat('MMMM d, yyyy - EEEE').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Labels Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'kWh',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 43),
                SizedBox(width: 1),
                Text(
                  'V',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 30),
                SizedBox(width: 8),
                Text(
                  'A',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 15),
                SizedBox(width: 20),
                Text(
                  'W',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 1),
                SizedBox(width: 25),
                Text(
                  'Runtime',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 4), // Spacing between labels and values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(
                  Icons.lightbulb, // Replace with your device icon
                  size: 40,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
                SizedBox(width: 20),
                Text(
                  '${widget.energy.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  '${widget.voltage.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 10), // Spacing between voltage and current
                Text(
                  '${widget.current.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 10), // Spacing between current and power
                Text(
                  '${widget.power.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 10), // Spacing between power and runtime
                Text(
                  '${widget.runtimehr}h ${widget.runtimemin}m ${widget.runtimesec}s', // Display runtime from database
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 72, 100, 68),
                  ),
                ),
                SizedBox(width: 10),
                Switch(
                  value: widget.isApplianceOn,
                  onChanged: widget.onToggleChanged,
                  activeTrackColor: Colors.green[700],
                  activeColor: Colors.green[900],
                  inactiveTrackColor: Colors.grey[400],
                  inactiveThumbColor: Colors.grey[300],
                ),
                // Delete Icon (conditionally visible with animation)
                if (_showDeleteIcon)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * math.pi / 12,
                        child: child,
                      );
                    },
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Device'),
                              content: Text(
                                  'Are you sure you want to delete this device?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDeleteIcon =
                                          false; // Hide the delete icon
                                    });
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                    _animationController
                                        .reset(); // Stop and reset the animation
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: Implement device deletion logic here
                                    // Remove the device from your data source
                                    // Update the UI to reflect the deletion
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: Text('Confirm',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 54, 83, 56),
                                      )),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24), // Increased spacing
            // Add and Remove Device Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to DeviceConfigurationScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceConfigurationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                    minimumSize: Size(180, 40), // Increased width to 180
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child: Text(
                    'Add a Device',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showDeleteIcon = !_showDeleteIcon;
                      if (_showDeleteIcon) {
                        _animationController.repeat(reverse: true);
                      } else {
                        _animationController.reset();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(180, 40), // Increased width to 180
                    backgroundColor: const Color.fromARGB(255, 202, 67, 67),
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child: Text(
                    'Remove a Device',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white, // Changed font color to white
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
