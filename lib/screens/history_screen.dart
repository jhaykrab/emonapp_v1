import 'package:intl/intl.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/models/user_data.dart';
import 'package:Emon/widgets/history_values_row.dart';
import 'package:Emon/widgets/history_labels_row.dart';
import 'package:Emon/widgets/history_container_widget.dart'; // Import the container widget

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedHistoryTabIndex = 0; // 0 for Daily, 1: Weekly, 2: Monthly
  int _selectedNavbarIndex = 3; // 3 for History
  final _pageController = PageController(initialPage: 0); // Start on Daily

  User? _user;
  String _userName = '';
  UserData? _userData;

  // Firebase Realtime Database reference for history data
  final DatabaseReference _historyRef = FirebaseDatabase.instance
      .ref('HistoryData'); // Update with your actual path

  // Variables to store history data
  List<Map<String, dynamic>> _dailyHistoryData = [];
  List<Map<String, dynamic>> _weeklyHistoryData = [];
  List<Map<String, dynamic>> _monthlyHistoryData = [];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _fetchHistoryData();
  }

  Future<void> _fetchUserData() async {
    final DatabaseService _dbService = DatabaseService();

    if (_user != null) {
      UserData? userData = await _dbService.getUserData(_user!.uid);

      if (mounted) {
        setState(() {
          _userData = userData;
          _userName = userData != null
              ? '${userData.firstName ?? ''} ${userData.lastName ?? ''}'
              : 'User Full Name';
        });
      }
    }
  }

  // Function to fetch history data from Firebase Realtime Database
  Future<void> _fetchHistoryData() async {
    // Daily data
    _historyRef.child('Daily').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _dailyHistoryData = data.values.toList().cast<Map<String, dynamic>>();
        });
      }
    });

    // Weekly data (replace 'Weekly' with your actual path)
    _historyRef.child('Weekly').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _weeklyHistoryData =
              data.values.toList().cast<Map<String, dynamic>>();
        });
      }
    });

    // Monthly data (replace 'Monthly' with your actual path)
    _historyRef.child('Monthly').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _monthlyHistoryData =
              data.values.toList().cast<Map<String, dynamic>>();
        });
      }
    });
  }

  void _onTimeButtonTapped(int index) {
    setState(() {
      _selectedHistoryTabIndex = index;
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
      // Add navigation logic if needed for other BottomNavigationBar items
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: 20),

            // Time selection buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimeButtonWidget(
                  label: 'Daily',
                  index: 0,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () => _onTimeButtonTapped(0),
                ),
                SizedBox(width: 16),
                TimeButtonWidget(
                  label: 'Weekly',
                  index: 1,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () => _onTimeButtonTapped(1),
                ),
                SizedBox(width: 16),
                TimeButtonWidget(
                  label: 'Monthly',
                  index: 2,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () => _onTimeButtonTapped(2),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Swipable History Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedHistoryTabIndex = index;
                  });
                },
                children: [
                  // Daily History Content
                  _buildDailyHistory(),

                  // Weekly History Content
                  _buildWeeklyHistory(),

                  // Monthly History Content
                  _buildMonthlyHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedNavbarIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Helper function to build Daily History content
  Widget _buildDailyHistory() {
    return ListView.builder(
      itemCount: _dailyHistoryData.length,
      itemBuilder: (context, index) {
        final data = _dailyHistoryData[index];
        return DeviceHistoryItem(
          energy: (data['energy'] ?? 0.0).toDouble(),
          voltage: (data['voltage'] ?? 0.0).toDouble(),
          current: (data['current'] ?? 0.0).toDouble(),
          power: (data['power'] ?? 0.0).toDouble(),
          runtimeHr: (data['runtimeHr'] ?? 0).toInt(),
          runtimeMin: (data['runtimeMin'] ?? 0).toInt(),
          runtimeSec: (data['runtimeSec'] ?? 0).toInt(),
        );
      },
    );
  }

  // Helper function to build Weekly History content
  Widget _buildWeeklyHistory() {
    return ListView.builder(
      itemCount: _weeklyHistoryData.length,
      itemBuilder: (context, index) {
        final data = _weeklyHistoryData[index];
        return DeviceHistoryItem(
          energy: (data['energy'] ?? 0.0).toDouble(),
          voltage: (data['voltage'] ?? 0.0).toDouble(),
          current: (data['current'] ?? 0.0).toDouble(),
          power: (data['power'] ?? 0.0).toDouble(),
          runtimeHr: (data['runtimeHr'] ?? 0).toInt(),
          runtimeMin: (data['runtimeMin'] ?? 0).toInt(),
          runtimeSec: (data['runtimeSec'] ?? 0).toInt(),
        );
      },
    );
  }

  // Helper function to build Monthly History content
  Widget _buildMonthlyHistory() {
    return ListView.builder(
      itemCount: _monthlyHistoryData.length,
      itemBuilder: (context, index) {
        final data = _monthlyHistoryData[index];
        return DeviceHistoryItem(
          energy: (data['energy'] ?? 0.0).toDouble(),
          voltage: (data['voltage'] ?? 0.0).toDouble(),
          current: (data['current'] ?? 0.0).toDouble(),
          power: (data['power'] ?? 0.0).toDouble(),
          runtimeHr: (data['runtimeHr'] ?? 0).toInt(),
          runtimeMin: (data['runtimeMin'] ?? 0).toInt(),
          runtimeSec: (data['runtimeSec'] ?? 0).toInt(),
        );
      },
    );
  }
}

// Widget to display individual device history item
class DeviceHistoryItem extends StatelessWidget {
  final double energy;
  final double voltage;
  final double current;
  final double power;
  final int runtimeHr;
  final int runtimeMin;
  final int runtimeSec;

  const DeviceHistoryItem({
    Key? key,
    required this.energy,
    required this.voltage,
    required this.current,
    required this.power,
    required this.runtimeHr,
    required this.runtimeMin,
    required this.runtimeSec,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HistoryContainerWidget(
      // Use the HistoryContainerWidget
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date
          Center(
            child: Text(
              DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 72, 100, 68),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Labels Row
          HistoryLabelsRow(),

          SizedBox(height: 4),

          // Values Row
          HistoryValuesRow(
            energy: energy,
            voltage: voltage,
            current: current,
            power: power,
            runtimeHr: runtimeHr,
            runtimeMin: runtimeMin,
            runtimeSec: runtimeSec,
          ),
        ],
      ),
    );
  }
}
