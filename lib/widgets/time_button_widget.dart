import 'package:flutter/material.dart';

class TimeButtonWidget extends StatelessWidget {
  final String label;
  final int index;
  final int selectedTabIndex;
  final VoidCallback onPressed;

  const TimeButtonWidget({
    Key? key,
    required this.label,
    required this.index,
    required this.selectedTabIndex,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedTabIndex == index;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color.fromARGB(255, 72, 100, 68)
            : Colors.transparent,
        side: BorderSide(
          color: const Color.fromARGB(255, 72, 100, 68),
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
}
