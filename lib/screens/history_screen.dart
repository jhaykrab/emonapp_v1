import 'package:intl/intl.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:Emon/services/database.dart';
import 'package:Emon/models/user_data.dart';
import 'package:Emon/widgets/history_values_row.dart';
import 'package:Emon/widgets/history_labels_row.dart';
import 'package:Emon/widgets/history_container_widget.dart'; // Import the container widget
import 'package:Emon/widgets/device_history_widget.dart';
import 'package:Emon/analytic_pages/realtime_analytics_page.dart' as Analytics;
import 'package:Emon/screens/realtime_page.dart' as Screen;

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

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Realtime Database reference for real-time data
  final DatabaseReference _realtimeRef =
      FirebaseDatabase.instance.ref('SensorReadings');

  // Variables to store history data
  List<Map<String, dynamic>> _dailyHistoryData = [];
  List<Map<String, dynamic>> _weeklyHistoryData = [];
  List<Map<String, dynamic>> _monthlyHistoryData = [];
  List<Map<String, dynamic>> _testModeData = [];

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

  // Function to fetch real-time data from Firebase Realtime Database
  Future<void> _fetchRealtimeData() async {
    _realtimeRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          // Assuming the real-time data structure, adjust as needed
          _dailyHistoryData = data.values.toList().cast<Map<String, dynamic>>();
        });
      }
    });
  }

  // Function to fetch historical data (daily, weekly, monthly, testmode) from Firestore
  Future<void> _fetchHistoryData() async {
    final uid = _user?.uid;

    if (uid != null) {
      // Fetch daily data from Firestore
      _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc('daily')
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _dailyHistoryData =
                List<Map<String, dynamic>>.from(doc.data()?['data'] ?? []);
          });
        }
      });

      // Fetch weekly data from Firestore
      _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc('weekly')
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _weeklyHistoryData =
                List<Map<String, dynamic>>.from(doc.data()?['data'] ?? []);
          });
        }
      });

      // Fetch monthly data from Firestore
      _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc('monthly')
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _monthlyHistoryData =
                List<Map<String, dynamic>>.from(doc.data()?['data'] ?? []);
          });
        }
      });

      // Fetch test mode data from Firestore
      _firestore
          .collection('users')
          .doc(uid)
          .collection('history')
          .doc('testmode')
          .get()
          .then((doc) {
        if (doc.exists) {
          setState(() {
            _testModeData =
                List<Map<String, dynamic>>.from(doc.data()?['data'] ?? []);
          });
        }
      });
    }
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
      appBar: AppBarWidget(
          userName: _userName), // Your custom AppBar with R-Time button
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
                TimeButtonWidget(
                  label: 'Weekly',
                  index: 1,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () => _onTimeButtonTapped(1),
                ),
                TimeButtonWidget(
                  label: 'Monthly',
                  index: 2,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () => _onTimeButtonTapped(2),
                ),
                TimeButtonWidget(
                  label: 'R-Time',
                  index: 3,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Analytics.RealTimeAnalyticsPage(),
                      ),
                    );
                  },
                ),
                TimeButtonWidget(
                  label: 'TestMode',
                  index: 4,
                  selectedTabIndex: _selectedHistoryTabIndex,
                  onPressed: () => _onTimeButtonTapped(4),
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
                  _buildDailyHistory(),
                  _buildWeeklyHistory(),
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
