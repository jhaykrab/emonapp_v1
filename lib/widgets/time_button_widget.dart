import 'package:flutter/material.dart';

class TimeButtonWidget extends StatelessWidget {
  final String label;
  final int index;
  final int selectedTabIndex;
  final VoidCallback onPressed;
  final double buttonWidth; // Add buttonWidth parameter
  final double fontSize; // Add fontSize parameter

  const TimeButtonWidget({
    Key? key,
    required this.label,
    required this.index,
    required this.selectedTabIndex,
    required this.onPressed,
    this.buttonWidth = 80.0, // Default button width
    this.fontSize = 12.0, // Default font size
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: index == selectedTabIndex
            ? const Color.fromARGB(255, 54, 83, 56)
            : const Color.fromARGB(255, 243, 250, 244),
        minimumSize: Size(buttonWidth, 30),
        padding: EdgeInsets.symmetric(
            horizontal: 18, vertical: 12), // Increased padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.0),
          side: BorderSide(
            color: const Color.fromARGB(255, 54, 83, 56),
            width: 1.5,
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
