import 'package:Emon/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:firebase_database/firebase_database.dart'; // Firebase Realtime Database
import 'package:Emon/services/database.dart';
import 'package:kdgaugeview/kdgaugeview.dart';
import 'package:gauge_indicator/gauge_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isApplianceOn = false; // Appliance state
  int _selectedIndex = 2; // Dashboard is selected by default (index 2)
  int _hoveredIndex = -1; // Track hovered item index

  final key = GlobalKey<KdGaugeViewState>();

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

  // Helper function to build individual gauges
  Widget _buildGauge({
    required double value, // Current energy value to show
    required String title, // Title of the gauge
    double? gaugeSize, // Optional parameter for gauge size
    double? fontSize, // Optional parameter for font size
  }) {
    return Center(
      child: SizedBox(
        height: gaugeSize ?? 150,
        width: gaugeSize ?? 150,
        child: RadialGauge(
          value: value / 100, // Normalize value to 0-1 range
          radius: (gaugeSize ?? 150) / 2, // Set radius based on gaugeSize
          axis: GaugeAxis(
            axisLabelStyle: TextStyle(fontSize: 12), // Style for axis labels
            ticks: [
              GaugeTick(value: 0, length: 0.1), // Customize tick length here
              GaugeTick(value: 25, length: 0.15),
              GaugeTick(value: 50, length: 0.2),
              GaugeTick(value: 75, length: 0.15),
              GaugeTick(value: 100, length: 0.1),
            ],
            pointers: [
              GaugePointer.needle(
                width: 2,
                pointerOffset: 0.2, // Adjust needle length indirectly
                color: Colors.black,
              ),
            ],
            // Use axis to customize the gauge fill
            axisLineStyle: GaugeAxisLineStyle(
              thickness: 15, // Set the thickness of the gauge line
              gradient: SweepGradient(
                colors: [
                  const Color.fromARGB(255, 46, 54, 45),
                  const Color.fromARGB(255, 72, 100, 68),
                  const Color.fromARGB(255, 105, 206, 109),
                  Colors.yellow,
                  const Color.fromARGB(255, 233, 80, 33),
                ],
              ),
            ),
          ),
          center: Text(
            '${value.toStringAsFixed(2)} kWh',
            style: TextStyle(
              fontSize: fontSize ?? 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 72, 100, 68),
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
                color: Color(0xFFe8f5e9),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            // Add Spacer() here to push the help icon to the right
            Spacer(),
            IconButton(
              icon: Icon(Icons.help_outline),
              color: Color(0xFFe8f5e9),
              onPressed: () {
                print("Help button pressed");
                // Add your help button functionality here
              },
            )
          ],
        ),
      ),
      body: Container(
        color: Colors.white, // Set body background to white
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 25.0),
              // Title: Realtime Consumption
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0), // Adjust padding if needed
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromARGB(255, 96, 167, 87),
                    width: 1.5,
                  ),
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize
                      .min, // This line makes the Row fit its content
                  mainAxisAlignment:
                      MainAxisAlignment.center, // This line centers the Row
                  children: [
                    Icon(
                      Icons.bolt,
                      color: const Color.fromARGB(255, 216, 201, 69),
                    ),
                    SizedBox(width: 8.0),
                    const Text(
                      "Realtime Consumption",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 96, 167, 87),
                      ),
                    ),
                    SizedBox(width: 12.0),
                  ],
                ),
              ),

              SizedBox(height: 50),

              _buildGauge(
                value: _energy, // Reflects real-time energy reading
                title: 'Energy',
                gaugeSize: 250,
                fontSize: 54,
              ),

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
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 54, 83, 56),
              const Color.fromARGB(255, 54, 83, 56),
            ],
          ),
        ),
        child: SizedBox(
          height: 70,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
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
                    duration: const Duration(milliseconds: 100),
                    padding: EdgeInsets.all(_selectedIndex == index
                        ? 6.0
                        : _hoveredIndex == index
                            ? 6.0
                            : 2.0), // Increase padding when selected
                    decoration: BoxDecoration(
                      color: _selectedIndex == index
                          ? const Color.fromARGB(255, 90, 105, 91)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: _selectedIndex == index
                          ? [
                              BoxShadow(
                                color: const Color.fromARGB(255, 90, 105, 91)
                                    .withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    transform: _selectedIndex == index
                        ? Matrix4.translationValues(0, -12, 0)
                        : Matrix4.identity(),
                    child: Icon(
                      index == 0
                          ? Icons.person
                          : index == 1
                              ? Icons.devices
                              : index == 2
                                  ? Icons.dashboard
                                  : index == 3
                                      ? Icons.analytics
                                      : Icons.settings,
                      size: _selectedIndex == index ? 30 : 26,
                      color: _selectedIndex == index ? Color(0xFFe8f5e9) : null,
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
            selectedLabelStyle: TextStyle(
              color: Colors.white,
            ),
            currentIndex: _selectedIndex,
            selectedItemColor: Color(0xFFe8f5e9),
            unselectedItemColor: const Color.fromARGB(255, 197, 194, 194),
            onTap: _onItemTapped,
            selectedFontSize: 10,
            unselectedFontSize: 9,
          ),
        ),
      ),
    );
  }
}
