import 'package:Emon/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:Emon/analytic_pages/realtime_analytics_page.dart';
import 'package:Emon/analytic_pages/daily_analytics_page.dart';

class HistoryScreen extends StatefulWidget {
  static const String routeName = '/history';

  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTabIndex = 0; // Tracks active tab (R-Time, Daily, etc.)
  int _selectedNavbarIndex = 3; // Analytics tab in bottom navigation
  late final PageController _pageController;
  String _userName = ''; // Stores fetched username
  User? _user;
  String? _userId; // Added userId variable
  bool _isLoading = true;

  // New variable for total energy
  double _totalEnergy = 0.0;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _userId = _user?.uid; // Initialize userId
    _pageController = PageController(initialPage: _selectedTabIndex);
    _fetchUserData();
    _fetchTotalEnergy(); // Fetch total energy data
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Fetches the user's name from the database
  Future<void> _fetchUserData() async {
    final DatabaseService _dbService = DatabaseService();
    if (_user != null) {
      UserData? userData = await _dbService.getUserData(_user!.uid);
      if (mounted) {
        setState(() {
          _userName = userData != null
              ? '${userData.firstName ?? ''} ${userData.lastName ?? ''}'
              : 'User Full Name';
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _userName = 'Guest';
          _isLoading = false;
        });
      }
    }
  }

  /// Simulates fetching total energy data
  Future<void> _fetchTotalEnergy() async {
    try {
      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay
      double fetchedEnergy = 3.5; // Example fetched energy value

      if (mounted) {
        setState(() {
          _totalEnergy = fetchedEnergy;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalEnergy = 0.0; // Default to zero if fetching fails
        });
      }
    }
  }

  /// Updates the tab index when a button is pressed
  void _onTimeButtonTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Updates the bottom navigation bar index
  void _onItemTapped(int index) {
    setState(() {
      _selectedNavbarIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Space above time buttons
                const SizedBox(height: 20), // Add spacing above buttons

                // Time Buttons Row
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Align buttons centrally
                  children: [
                    TimeButtonWidget(
                      label: 'R-Time',
                      index: 0,
                      selectedTabIndex: _selectedTabIndex,
                      onPressed: () => _onTimeButtonTapped(0),
                    ),
                    TimeButtonWidget(
                      label: 'Daily',
                      index: 1,
                      selectedTabIndex: _selectedTabIndex,
                      onPressed: () => _onTimeButtonTapped(1),
                    ),
                    TimeButtonWidget(
                      label: 'TestMode',
                      index: 2,
                      selectedTabIndex: _selectedTabIndex,
                      onPressed: () => _onTimeButtonTapped(2),
                    ),
                    TimeButtonWidget(
                      label: 'Weekly',
                      index: 3,
                      selectedTabIndex: _selectedTabIndex,
                      onPressed: () => _onTimeButtonTapped(3),
                    ),
                    TimeButtonWidget(
                      label: 'Monthly',
                      index: 4,
                      selectedTabIndex: _selectedTabIndex,
                      onPressed: () => _onTimeButtonTapped(4),
                    ),
                  ],
                ),

                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    children: [
                      RealTimeAnalyticsPage(totalEnergy: _totalEnergy),
                      DailyAnalyticsPage(
                          userId: _userId!), // Pass the userId here
                      // DailyAnalyticsPage(),
                      const Placeholder(), // TestModeAnalyticsPage(),
                      const Placeholder(), // WeeklyAnalyticsPage(),
                      const Placeholder(), // MonthlyAnalyticsPage(),
                    ],
                  ),
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
