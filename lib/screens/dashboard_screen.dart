import 'package:Emon/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:firebase_database/firebase_database.dart'; // Firebase Realtime Database
import 'package:Emon/services/database.dart';
import 'package:Emon/widgets/gauge_widget.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:Emon/widgets/device_info_widget.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:Emon/screens/history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  int _selectedNavbarIndex = 2;
  final _pageController = PageController();

  // Firebase
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('SensorReadings');
  User? _user;
  String _userName = '';
  double _voltage = 0.0;
  double _current = 0.0;
  double _power = 0.0;
  double _energy = 0.0;
  int _runtimehr = 0;
  int _runtimemin = 0;
  int _runtimesec = 0;
  bool _isApplianceOn = false;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
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
        _runtimehr = (data?['runtimehr'] ?? 0).toInt();
        _runtimemin = (data?['runtimemin'] ?? 0).toInt();
        _runtimesec = (data?['runtimesec'] ?? 0).toInt();
        _isApplianceOn = data?['applianceState'] ?? false;
      });
    });
  }

  void _onTimeButtonTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavbarIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 25.0),
              // Title: Consumption
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
                    Text(
                      _selectedTabIndex == 0
                          ? "Realtime Consumption"
                          : _selectedTabIndex == 1
                              ? "Daily Consumption"
                              : _selectedTabIndex == 2
                                  ? "Weekly Consumption"
                                  : "Monthly Consumption",
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

              // Conditionally render gauge
              if (_selectedTabIndex == 0)
                Center(
                  child: GaugeWidget(value: _energy),
                ),
              SizedBox(height: 20),

              // Time selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TimeButtonWidget(
                    label: 'R-Time',
                    index: 0,
                    selectedTabIndex: _selectedTabIndex,
                    onPressed: () => _onTimeButtonTapped(0),
                  ),
                  SizedBox(width: 16),
                  TimeButtonWidget(
                    label: 'Daily',
                    index: 1,
                    selectedTabIndex: _selectedTabIndex,
                    onPressed: () => _onTimeButtonTapped(1),
                  ),
                  SizedBox(width: 16),
                  TimeButtonWidget(
                    label: 'Weekly',
                    index: 2,
                    selectedTabIndex: _selectedTabIndex,
                    onPressed: () => _onTimeButtonTapped(2),
                  ),
                  SizedBox(width: 16),
                  TimeButtonWidget(
                    label: 'Monthly',
                    index: 3,
                    selectedTabIndex: _selectedTabIndex,
                    onPressed: () => _onTimeButtonTapped(3),
                  ),
                  SizedBox(width: 16),
                ],
              ),

              SizedBox(height: 50),

              // View History Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to HistoryScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                  minimumSize: Size(180, 40),
                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  'View History',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Device Information and Toggle Container
              DeviceInfoWidget(
                energy: _energy,
                voltage: _voltage,
                current: _current,
                power: _power,
                runtimehr: _runtimehr,
                runtimemin: _runtimemin,
                runtimesec: _runtimesec,
                isApplianceOn: _isApplianceOn,
                onToggleChanged: (value) {
                  setState(() {
                    _isApplianceOn = value;
                    _databaseRef.update({'applianceState': _isApplianceOn});
                  });
                },
              ),

              SizedBox(height: 20),

              // PageView for swipeable content
              SizedBox(
                height: 400,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  children: [
                    // R-Time Content (empty, as the gauge is already displayed)
                    Container(),
                    // Daily Content
                    Center(child: Text('This is Daily Page')),
                    // Weekly Content
                    Center(child: Text('This is Weekly Page')),
                    // Monthly Content
                    Center(child: Text('This is Monthly Page')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedNavbarIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
