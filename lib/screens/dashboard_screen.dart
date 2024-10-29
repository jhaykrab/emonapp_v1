import 'package:Emon/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication
import 'package:firebase_database/firebase_database.dart'; // Firebase Realtime Database
import 'package:Emon/services/database.dart';
import 'package:gauge_indicator/gauge_indicator.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:kdgaugeview/kdgaugeview.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showCheckboxes = false; // Flag to control checkbox visibility
  List<bool> _selectedDevices = []; // Track selected devices for removal
  bool _isApplianceOn = false; // Appliance state
  int _selectedTabIndex =
      0; // Selected index for buttons (0: R-Time, 1: Daily, 2: Weekly, 3: Monthly)
  int _selectedNavbarIndex =
      2; // Selected index for BottomNavigationBar (Dashboard)
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
  int _runtimehr = 0;
  int _runtimemin = 0;
  int _runtimesec = 0;

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
        _runtimehr = (data?['runtimehr'] ?? 0).toInt();
        _runtimemin = (data?['runtimemin'] ?? 0).toInt();
        _runtimesec = (data?['runtimesec'] ?? 0).toInt();
        _isApplianceOn = data?['applianceState'] ?? false;
      });
    });
  }

  // Function to handle bottom navbar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedNavbarIndex = index;
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
    required String title, // Title of the gauge (not used in this example)
    double? gaugeSize, // Optional parameter for gauge size
    double? fontSize, // Optional parameter for font size
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedRadialGauge(
          duration: const Duration(seconds: 1),
          curve: Curves.elasticOut,
          radius: 180,
          key: key,
          value: value, // Use the provided 'value' for the gauge

          axis: GaugeAxis(
            min: 0,
            max: 18,
            degrees: 180,
            style: const GaugeAxisStyle(
              thickness: 20,
              background: Color(0xFFDFE2EC),
              segmentSpacing: 4,
            ),
            progressBar: GaugeProgressBar.rounded(
              color: null,
              gradient: const GaugeAxisGradient(
                colors: [
                  Color.fromARGB(255, 69, 204, 73),
                  Color.fromARGB(255, 202, 60, 41)
                ],
              ),
            ),
          ),
        ), // AnimatedRadialGauge
        Column(
          // Use a Column to arrange the Text widgets
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 30),
            Text(
              'Today',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 72, 100, 68),
              ),
            ),
            Row(
              // Wrap value and kWh in a Row
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: value >= 18
                        ? Colors.red
                        : value >= 15
                            ? Colors.deepOrangeAccent
                            : value >= 12
                                ? const Color.fromARGB(255, 245, 179, 93)
                                : value >= 9
                                    ? const Color.fromARGB(255, 150, 221, 36)
                                    : value >= 6
                                        ? const Color.fromARGB(
                                            255, 131, 223, 78)
                                        : value >= 3
                                            ? const Color.fromARGB(
                                                255, 132, 247, 79)
                                            : Colors.green, // Conditional color
                  ),
                ),

                SizedBox(width: 4), // Add some spacing between value and kWh
                Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    'kWh', // Text next to the value
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // Add space for the consumption message
            // Conditional text for energy consumption message
            Text(
              value == 0.00
                  ? 'No Energy Consumed' // Condition for 0 kWh
                  : value <= 6
                      ? 'Low Energy Consumption'
                      : value > 6 && value <= 9
                          ? 'Average Energy Consumption'
                          : value > 9 && value <= 12
                              ? 'High Energy Consumption'
                              : 'Extremely High Consumption',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: value == 0 // Color for 0 kWh (you can customize this)
                    ? Colors.grey
                    : value <= 6
                        ? Colors.green
                        : value > 6 && value <= 9
                            ? const Color.fromARGB(255, 115, 180, 9)
                            : value > 9 && value <= 12
                                ? Colors.orange
                                : Colors.red,
              ),
            ),
          ],
        ),
        Positioned(
          top: 160,
          left: 30,
          child: Text('0', style: TextStyle(fontSize: 16)),
        ),
        Positioned(
          top: 102,
          left: 48,
          child: Text('3', style: TextStyle(fontSize: 16)),
        ),
        Positioned(
          top: 45,
          left: 99,
          child: Text('6', style: TextStyle(fontSize: 16)),
        ),
        Positioned(
          top: 24,
          left: 173,
          child: Text('9', style: TextStyle(fontSize: 16)),
        ),
        Positioned(
          top: 45,
          left: 243,
          child: Text('12', style: TextStyle(fontSize: 16)),
        ),
        Positioned(
          top: 102,
          left: 293,
          child: Text('15', style: TextStyle(fontSize: 16)),
        ),
        Positioned(
          top: 160,
          left: 310,
          child: Text('18', style: TextStyle(fontSize: 16)),
        ),
      ], // End of Stack children
    ); // Stack
  } // _buildGauge

  // Helper function to build time selection buttons
  Widget _buildTimeButton(String label, int index) {
    final isSelected =
        _selectedTabIndex == index; // Check if button is selected

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedTabIndex = index;
          // Animate to the selected page
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300), // Adjust animation duration
            curve: Curves.easeInOut,
          );
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color.fromARGB(255, 72, 100, 68) // Dark green when selected
            : Colors.transparent,
        side: BorderSide(
          color: const Color.fromARGB(255, 72, 100, 68), // Green outline
          width: 2.0,
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: isSelected
              ? Colors.white
              : const Color.fromARGB(255, 72, 100, 68),
        ),
      ),
    );
  }

  // PageController to control the PageView
  final _pageController = PageController();

  @override
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
              // Title: Consumption (Dynamically changes based on selected tab)
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
              _selectedTabIndex == 0
                  ? Center(
                      child: _buildGauge(
                        value: _energy,
                        title: '',
                        gaugeSize: 250,
                        fontSize: 54,
                      ),
                    )
                  : SizedBox.shrink(),

              SizedBox(height: 20), // Space above buttons

              // Time selection buttons (placed outside PageView)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeButton('R-Time', 0),
                  SizedBox(width: 16), // Space between buttons
                  _buildTimeButton('Daily', 1),
                  SizedBox(width: 16),
                  _buildTimeButton('Weekly', 2),
                  SizedBox(width: 16),
                  _buildTimeButton('Monthly', 3),
                  SizedBox(width: 16),
                ],
              ),

              SizedBox(height: 20), // Space between buttons and content

              // Device Information and Toggle Container
              Center(
                child: Container(
                  width: 450,
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                        255, 223, 236, 219), // Light green background
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
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Date and Day of the Week
                      Center(
                        child: Text(
                          DateFormat('MMMM d, yyyy - EEEE')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(
                                255, 72, 100, 68), // Dark green text
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
                            '${_energy.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 72, 100, 68),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            '${_voltage.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 72, 100, 68),
                            ),
                          ),
                          SizedBox(
                              width: 10), // Spacing between voltage and current
                          Text(
                            '${_current.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 72, 100, 68),
                            ),
                          ),
                          SizedBox(
                              width: 10), // Spacing between current and power
                          Text(
                            '${_power.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 72, 100, 68),
                            ),
                          ),
                          SizedBox(
                              width: 10), // Spacing between power and runtime
                          Text(
                            '${_runtimehr}: $_runtimemin: $_runtimesec', // Display runtime from database
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 72, 100, 68),
                            ),
                          ),
                          SizedBox(width: 10),
                          Switch(
                            value: _isApplianceOn,
                            onChanged: (value) {
                              setState(() {
                                _isApplianceOn = value;
                                // Update Firebase Realtime Database with the new appliance state
                                _databaseRef
                                    .update({'applianceState': _isApplianceOn});
                              });
                            },
                            activeTrackColor: Colors.green[700],
                            activeColor: Colors.green[900],
                            inactiveTrackColor: Colors.grey[400],
                            inactiveThumbColor: Colors.grey[300],
                          ),
                          SizedBox(width: 16),
                          IconButton(
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
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // TODO: Implement device deletion logic here
                                          // Remove the device from your data source
                                          // Update the UI to reflect the deletion
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        child: Text('Confirm'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
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
                              // TODO: Implement Add Device functionality
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 54, 83, 56),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20), // Space above buttons

              // PageView for swipeable content
              SizedBox(
                height: 400, // Set a fixed height for the PageView
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  children: [
                    // R-Time Content
                    Container(), // Empty container for R-Time (gauge is already displayed)

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
                    padding: EdgeInsets.all(_selectedNavbarIndex == index
                        ? 6.0
                        : _hoveredIndex == index
                            ? 6.0
                            : 2.0), // Increase padding when selected
                    decoration: BoxDecoration(
                      color: _selectedNavbarIndex == index
                          ? const Color.fromARGB(255, 90, 105, 91)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: _selectedNavbarIndex == index
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
                    transform: _selectedNavbarIndex == index
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
                      size: _selectedNavbarIndex == index ? 30 : 26,
                      color: _selectedNavbarIndex == index
                          ? Color(0xFFe8f5e9)
                          : null,
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
            currentIndex: _selectedNavbarIndex,
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
