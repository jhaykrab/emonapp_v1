// time_buttons.dart
import 'package:flutter/material.dart';
import 'package:Emon/widgets/time_button_widget.dart';

class TimeButtons extends StatelessWidget {
  final PageController pageController;
  final int selectedTabIndex;
  final ValueChanged<int> setSelectedTabIndex;
  final ValueChanged<int> onTimeButtonTapped; // Add this parameter

  const TimeButtons({
    Key? key,
    required this.pageController,
    required this.selectedTabIndex,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped, // Initialize it here
  }) : super(key: key);

  /// Handles the button tap and updates the selected tab and page.
  void _handleTimeButtonTapped(int index) {
    setSelectedTabIndex(index);
    pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeButton('R-Time', 0),
            _buildTimeButton('Daily', 1),
            _buildTimeButton('Weekly', 2),
            _buildTimeButton('Monthly', 3),
            _buildTimeButton('Test Mode', 4),
          ],
        ),
        const SizedBox(height: 16), // Adds spacing between rows
      ],
    );
  }

  /// Builds an individual TimeButtonWidget.
  Widget _buildTimeButton(String label, int index) {
    return TimeButtonWidget(
      label: label,
      index: index,
      selectedTabIndex: selectedTabIndex,
      onPressed: () => _handleTimeButtonTapped(index),
    );
  }
}
