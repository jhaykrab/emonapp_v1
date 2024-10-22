import 'package:Emon/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:firebase_database/firebase_database.dart'; // Firebase Realtime Database
import 'package:Emon/services/database.dart'; // Your custom DatabaseService

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isApplianceOn = false; // Appliance state
  int _selectedIndex = 2; // Dashboard is selected by default (index 2)
  int _hoveredIndex = -1; // Track hovered item index

  // Firebase Realtime Database reference for sensor readings
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('SensorReadings');

  User? _user; // Firebase Auth current user
  String _userName = ''; // Displayed user's full name

  // Variables to store energy data from Firebase Realtime Database
  double _voltage = 0.0;
  double _current = 0.0;
  double _power = 0.0;
  double _energy = 0.0;

  UserData? _userData; // User data fetched from Firestore

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser; // Get the current user
    _fetchUserData(); // Fetch user details from Firestore
    _listenToSensorReadings();
  }

  // Function to fetch user data (firstName, lastName) from Firestore
  Future<void> _fetchUserData() async {
    final DatabaseService _dbService =
        DatabaseService(); // Instance of your DatabaseService

    if (_user != null) {
      UserData? userData =
          await _dbService.getUserData(_user!.uid); // Fetch data by UID

      if (mounted) {
        setState(() {
          _userData = userData;
          _userName = userData != null
              ? '${userData.firstName ?? ''} ${userData.lastName ?? ''}'
              : 'User Full Name'; // Fallback to placeholder if no data
        });
      }
    }
  }

  // Firebase Realtime Database listener for sensor readings
  void _listenToSensorReadings() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      setState(() {
        _voltage = (data?['voltage'] ?? 0.0).toDouble();
        _current = (data?['current'] ?? 0.0).toDouble();
        _power = (data?['power'] ?? 0.0).toDouble();
        _energy = (data?['energy'] ?? 0.0).toDouble();
        _isApplianceOn = data?['applianceState'] ?? false;
      });
    });
  }

  // Function to handle bottom navbar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Add navigation logic if necessary for different tabs
    });
  }

  // Function to handle hover state for navbar items
  void _onItemHover(int index) {
    setState(() {
      _hoveredIndex = index; // Update hovered index on mouse hover
    });
  }

  // Reset hover state on mouse exit
  void _onItemExit() {
    setState(() {
      _hoveredIndex = -1; // Reset hovered index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        shadowColor: Colors.grey[200],
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/ic_launcher.png'),
              radius: 20,
            ),
            SizedBox(width: 10),
            Text(
              _userName, // Display fetched user name
              style: TextStyle(
                color: const Color.fromARGB(255, 72, 100, 68),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            // Add Spacer() here to push the help icon to the right
            Spacer(),
            IconButton(
              icon: Icon(Icons.help_outline),
              color: Color.fromARGB(255, 72, 100, 68),
              onPressed: () {
                print("Help button pressed");
                // Add your help button functionality here
              },
            )
          ],
        ),
      ),
      body: Container(
        // Wrap the body content with a Container
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFf5f5f5),
              Color(0xFFe8f5e9)
            ], // Your gradient colors
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display real-time energy data
            Text('Voltage: ${_voltage.toStringAsFixed(2)} V'),
            Text('Current: ${_current.toStringAsFixed(2)} A'),
            Text('Power: ${_power.toStringAsFixed(2)} W'),
            Text('Total Energy: ${_energy.toStringAsFixed(2)} kWh'),

            // Toggle button to control the appliance
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isApplianceOn ? 'Appliance On' : 'Appliance Off'),
                const SizedBox(width: 10),
                Switch(
                  value: _isApplianceOn,
                  onChanged: (value) {
                    setState(() {
                      _isApplianceOn = value;
                      // Update Firebase Realtime Database with the new appliance state
                      _databaseRef.update({'applianceState': _isApplianceOn});
                    });
                  },
                  activeTrackColor: Colors.green[700],
                  activeColor: Colors.green[900],
                  inactiveTrackColor: Colors.grey[400],
                  inactiveThumbColor: Colors.grey[300],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 70,
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 4,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: List.generate(
            5,
            (index) => BottomNavigationBarItem(
              icon: MouseRegion(
                onEnter: (_) => _onItemHover(index),
                onExit: (_) => _onItemExit(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _selectedIndex == index
                        ? const Color.fromARGB(255, 194, 228, 155)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    index == 0
                        ? Icons.person
                        : index == 1
                            ? Icons.devices
                            : index == 2
                                ? Icons.dashboard // Dashboard at center
                                : index == 3
                                    ? Icons.analytics
                                    : Icons.settings,
                    size: 26,
                  ),
                ),
              ),
              label: (index == 0
                  ? 'Profile'
                  : index == 1
                      ? 'Devices'
                      : index == 2
                          ? 'Dashboard'
                          : index == 3
                              ? 'History'
                              : 'Settings'),
            ),
          ),
          currentIndex: _selectedIndex,
          selectedItemColor: const Color.fromARGB(255, 72, 100, 68),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          selectedFontSize: 11,
          unselectedFontSize: 9,
        ),
      ),
    );
  }
}
