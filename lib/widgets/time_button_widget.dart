import 'package:flutter/material.dart';

class TimeButtonWidget extends StatelessWidget {
  final String label;
  final int index;
  final int selectedTabIndex;
  final VoidCallback onPressed;
  final double buttonWidth; // Button width
  final double fontSize; // Font size

  const TimeButtonWidget({
    Key? key,
    required this.label,
    required this.index,
    required this.selectedTabIndex,
    required this.onPressed,
    this.buttonWidth = 60.0, // Reduced button width
    this.fontSize = 10.0, // Reduced font size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: index == selectedTabIndex
            ? const Color.fromARGB(255, 54, 83, 56)
            : const Color.fromARGB(255, 243, 250, 244),
        minimumSize: Size(buttonWidth, 24), // Reduced button height
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 10), // Increased vertical padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.0), // Smaller border radius
          side: BorderSide(
            color: const Color.fromARGB(255, 54, 83, 56),
            width: 1.0, // Thinner border
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
          color: index == selectedTabIndex
              ? Colors.white
              : const Color.fromARGB(255, 54, 83, 56), // Dark green text
        ),
      ),
    );
  }
}
