// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/widgets/gauge_widget.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:Emon/widgets/device_info_widget.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:Emon/screens/history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Emon/models/appliance.dart';
import 'package:Emon/constants.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:Emon/providers/appliance_provider.dart';
import 'package:Emon/models/user_data.dart';
import 'realtime_page.dart';
import 'daily_page.dart';
import 'weekly_page.dart';
import 'monthly_page.dart';
import 'appliance_list.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  int _selectedNavbarIndex = 2;
  late final PageController _pageController;
  bool _isLoading = true;

  List<Appliance> _appliances = [];

  Map<String, IconData> applianceIcons = {
    'lightbulb': Icons.lightbulb_outline,
    'fan': Icons.air,
    'tv': Icons.tv,
    'refrigerator': Icons.kitchen,
  };

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
  StreamSubscription<DatabaseEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _pageController = PageController(initialPage: _selectedTabIndex);
    _fetchUserData();
    _listenToSensorReadings();
    _fetchApplianceData().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
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

  Future<void> _fetchApplianceData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('registered_appliances')
            .get();

        setState(() {
          _appliances = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String dbPath =
                _getDbPathForSerialNumber(data['deviceSerialNumber']);
            return Appliance(
              name: data['applianceName'] ?? '',
              applianceType: data['applianceType'] ?? 'unknown',
              energy: (data['energy'] ?? 0.0).toDouble(),
              voltage: (data['voltage'] ?? 0.0).toDouble(),
              current: (data['current'] ?? 0.0).toDouble(),
              power: (data['power'] ?? 0.0).toDouble(),
              runtimehr: (data['runtimehr'] ?? 0).toInt(),
              runtimemin: (data['runtimemin'] ?? 0).toInt(),
              runtimesec: (data['runtimesec'] ?? 0).toInt(),
              isApplianceOn: data['isOn'] ?? false,
              documentId: doc.id,
              serialNumber: data['deviceSerialNumber'] ?? '',
              onToggleChanged: (value) async {}, // Make this asynchronous
              dbPath: dbPath,
            );
          }).toList();
          _isLoading = false; // Set loading to false after fetching data
        });
      } catch (e) {
        print('Error fetching appliance data: $e');
        if (mounted) {
          setState(() {
            _isLoading = false; // Set loading to false even on error
          });
        }
      }
    }
  }

  String _getDbPathForSerialNumber(String serialNumber) {
    switch (serialNumber) {
      case '11032401':
        return 'SensorReadings';
      case '11032402':
        return 'SensorReadings_2';
      case '11032403':
        return 'SensorReadings_3';
      default:
        return '';
    }
  }

  void _addAppliance(Appliance newAppliance) {
    setState(() {
      _appliances.add(newAppliance);
    });
  }

  void _listenToSensorReadings() {
    _realtimeSubscription = _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (mounted) {
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
      }
    });
  }

  void setSelectedTabIndex(int index) {
    if (mounted) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavbarIndex = index;
    });
  }

  // Method to handle TimeButton taps:
  void _onTimeButtonTapped(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  PageController get pageController => _pageController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 54, 83, 56)),
            )
          : PageView(
              // PageView to manage page transitions
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              children: <Widget>[
                // Removed const for rebuilding

                RealTimePage(
                  selectedTabIndex: _selectedTabIndex,
                  setSelectedTabIndex: setSelectedTabIndex,
                  pageController: _pageController, // Pass pageController
                  onTimeButtonTapped: _onTimeButtonTapped,
                ),
                DailyPage(
                  selectedTabIndex: _selectedTabIndex,
                  setSelectedTabIndex: setSelectedTabIndex,
                  pageController: _pageController, // Pass pageController
                  onTimeButtonTapped: _onTimeButtonTapped,
                ),
                WeeklyPage(
                  selectedTabIndex: _selectedTabIndex,
                  setSelectedTabIndex: setSelectedTabIndex,
                  pageController: _pageController, // Pass pageController
                  onTimeButtonTapped: _onTimeButtonTapped,
                ),
                MonthlyPage(
                  selectedTabIndex: _selectedTabIndex,
                  setSelectedTabIndex: setSelectedTabIndex,
                  pageController: _pageController, // Pass pageController
                  onTimeButtonTapped: _onTimeButtonTapped,
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedNavbarIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
