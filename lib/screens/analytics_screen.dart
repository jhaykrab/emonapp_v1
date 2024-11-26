import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:Emon/analytics_pages/realtime_analytics_page.dart';
import 'package:Emon/analytics_pages/daily_analytics_page.dart';
import 'package:Emon/analytics_pages/weekly_analytics_page.dart';
import 'package:Emon/analytics_pages/monthly_analytics_page.dart';
import 'package:Emon/analytics_pages/testmode_analytics_page.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedAnalyticsTabIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  void _onTimeButtonTapped(int index) {
    setState(() {
      _selectedAnalyticsTabIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: const Color.fromARGB(255, 72, 100, 68),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Time selection buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TimeButtonWidget(
                label: 'R-Time',
                index: 0,
                selectedTabIndex: _selectedAnalyticsTabIndex,
                onPressed: () => _onTimeButtonTapped(0),
              ),
              const SizedBox(width: 16),
              TimeButtonWidget(
                label: 'Daily',
                index: 1,
                selectedTabIndex: _selectedAnalyticsTabIndex,
                onPressed: () => _onTimeButtonTapped(1),
              ),
              const SizedBox(width: 16),
              TimeButtonWidget(
                label: 'Weekly',
                index: 2,
                selectedTabIndex: _selectedAnalyticsTabIndex,
                onPressed: () => _onTimeButtonTapped(2),
              ),
              const SizedBox(width: 16),
              TimeButtonWidget(
                label: 'Monthly',
                index: 3,
                selectedTabIndex: _selectedAnalyticsTabIndex,
                onPressed: () => _onTimeButtonTapped(3),
              ),
              const SizedBox(width: 16),
              TimeButtonWidget(
                label: 'Testmode',
                index: 4,
                selectedTabIndex: _selectedAnalyticsTabIndex,
                onPressed: () => _onTimeButtonTapped(4),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // PageView for Analytics Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedAnalyticsTabIndex = index;
                });
              },
              children: const [
                RealtimeAnalyticsPage(),
                DailyAnalyticsPage(),
                WeeklyAnalyticsPage(),

                /*
                MonthlyAnalyticsPage(),
                TestmodeAnalyticsPage(),

                */
              ],
            ),
          ),
        ],
      ),
    );
  }
}
