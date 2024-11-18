// time_buttons.dart
import 'package:flutter/material.dart';
import 'package:Emon/widgets/time_button_widget.dart';
import 'package:Emon/screens/dashboard_screen.dart';

class TimeButtons extends StatelessWidget {
  final PageController pageController; // Keep pageController
  final int selectedTabIndex;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped; // Add the callback as a parameter

  const TimeButtons({
    Key? key,
    required this.pageController,
    required this.selectedTabIndex,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped, // Make it required
  }) : super(key: key);

  void _onTimeButtonTapped(int index) {
    setSelectedTabIndex(index);
    pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TimeButtonWidget(
          label: 'R-Time',
          index: 0,
          selectedTabIndex: selectedTabIndex,
          onPressed: () => _onTimeButtonTapped(0),
        ),
        TimeButtonWidget(
          label: 'Daily',
          index: 1,
          selectedTabIndex: selectedTabIndex,
          onPressed: () => _onTimeButtonTapped(1),
        ),
        TimeButtonWidget(
          label: 'Weekly',
          index: 2,
          selectedTabIndex: selectedTabIndex,
          onPressed: () => _onTimeButtonTapped(2),
        ),
        TimeButtonWidget(
          label: 'Monthly',
          index: 3,
          selectedTabIndex: selectedTabIndex,
          onPressed: () => _onTimeButtonTapped(3),
        ),
      ],
    );
  }
}
