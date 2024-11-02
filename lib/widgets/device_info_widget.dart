import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math; // Import math library for animation

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
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 0.0),
        margin: EdgeInsets.only(top: 40.0),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 72, 100, 68),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Row for Appliance Icon/Toggle and Readings/Units/Values
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column for Appliance Icon and Toggle
                Column(
                  children: [],
                ),

                SizedBox(width: 16), // Spacing between icon/toggle and readings

                // Column for Readings, Units, and Values
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Readings Titles Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20),
                          _buildReadingTitle('Energy'),
                          SizedBox(width: 15),
                          _buildReadingTitle('Voltage'),
                          SizedBox(width: 15),
                          _buildReadingTitle('Current'),
                          SizedBox(width: 15),
                          _buildReadingTitle('Power'),
                          SizedBox(width: 15),
                          _buildReadingTitle('Runtime'),
                          SizedBox(width: 40),
                        ],
                      ),

                      SizedBox(height: 4), // Reduced spacing

                      // Units Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(width: 80),
                          _buildUnit('kWh'),
                          SizedBox(width: 40),
                          _buildUnit('V'),
                          SizedBox(width: 40),
                          _buildUnit('A'),
                          SizedBox(width: 40),
                          _buildUnit('W'),
                          SizedBox(width: 40),
                          _buildUnit('h:m:s'),
                          SizedBox(width: 100),
                        ],
                      ),

                      SizedBox(height: 8), // Reduced spacing

                      // Values Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Icon(
                              Icons.lightbulb,
                              size: 36, // Reduced icon size
                              color: const Color.fromARGB(255, 72, 100, 68),
                            ),
                          ),
                          _buildReadingValue(widget.energy.toStringAsFixed(2)),
                          _buildReadingValue(widget.voltage.toStringAsFixed(1)),
                          _buildReadingValue(widget.current.toStringAsFixed(2)),
                          _buildReadingValue(widget.power.toStringAsFixed(1)),
                          _buildReadingValue(
                              '${widget.runtimehr}:${widget.runtimemin}:${widget.runtimesec}'),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: widget.isApplianceOn,
                              onChanged: widget.onToggleChanged,
                              activeTrackColor: Colors.green[700],
                              activeColor: Colors.green[900],
                              inactiveTrackColor: Colors.grey[400],
                              inactiveThumbColor: Colors.grey[300],
                            ),
                          ),
                          // Delete Icon (conditionally visible with animation)
                          if (_showDeleteIcon)
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _animationController.value *
                                      2 *
                                      math.pi /
                                      12,
                                  child: child,
                                );
                              },
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmationDialog();
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Add and Remove Device Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildElevatedButton(
                  'Add a Device',
                  const Color.fromARGB(255, 54, 83, 56),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupApplianceScreen(),
                      ),
                    );
                  },
                ),
                _buildElevatedButton(
                  'Remove a Device',
                  const Color.fromARGB(255, 202, 67, 67),
                  () {
                    setState(() {
                      _showDeleteIcon = !_showDeleteIcon;
                      if (_showDeleteIcon) {
                        _animationController.repeat(reverse: true);
                      } else {
                        _animationController.reset();
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to build reading titles
  Widget _buildReadingTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
    );
  }

  // Helper function to build reading values
  Widget _buildReadingValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
    );
  }

  // Helper function to build unit labels
  Widget _buildUnit(String unit) {
    return Text(
      unit,
      style: TextStyle(
        fontSize: 10,
        color: const Color.fromARGB(255, 72, 100, 68),
      ),
    );
  }

  // Helper function to build elevated buttons
  Widget _buildElevatedButton(
      String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(160, 40),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
      ),
    );
  }

  // Function to show a confirmation dialog before removing a device
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Device',
            style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete this device?',
                  style: TextStyle(color: Color.fromARGB(255, 22, 22, 22)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Color.fromARGB(255, 54, 83, 56)),
              ),
              onPressed: () {
                setState(() {
                  _showDeleteIcon = false;
                });
                Navigator.of(context).pop();
                _animationController.reset();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(color: Color.fromARGB(255, 114, 18, 18)),
              ),
              onPressed: () {
                // TODO: Implement device deletion logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
