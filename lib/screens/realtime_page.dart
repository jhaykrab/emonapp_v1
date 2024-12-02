import 'package:flutter/material.dart';
import 'package:Emon/widgets/gauge_widget.dart';
import 'package:Emon/widgets/device_info_widget.dart';
import 'package:provider/provider.dart';
import 'package:Emon/providers/appliance_provider.dart';
import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:Emon/widgets/time_buttons.dart'; // Import TimeButtons
import 'package:Emon/screens/dashboard_screen.dart'; // Import DashboardScreen for GlobalKey
import 'dart:async';

class RealTimePage extends StatelessWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped; // Add this callback

  const RealTimePage({
    Key? key,
    required this.selectedTabIndex,
    required this.pageController,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped, // Required callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final applianceProvider = Provider.of<ApplianceProvider>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title Section: Realtime Consumption
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    const Color.fromARGB(255, 54, 83, 56), // Dark green border
                width: 2.0, // Increased border width
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bolt,
                    color:
                        Color.fromARGB(255, 231, 175, 22)), // Icon with color
                SizedBox(width: 8),
                Text(
                  "Realtime Consumption",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          Color.fromARGB(255, 54, 83, 56)), // Text with color
                ),
              ],
            ),
          ),

          const SizedBox(height: 50),
          // Gauge Widget displaying consumption stats
          const GaugeWidget(),
          // Time Buttons for selecting time ranges (Daily, Weekly, etc.)
          const SizedBox(height: 20),
          TimeButtons(
            pageController: pageController, // Pass the received pageController
            selectedTabIndex: selectedTabIndex,
            setSelectedTabIndex: setSelectedTabIndex,
            onTimeButtonTapped: onTimeButtonTapped, // Pass the callback
          ),

          // Device info section: List of appliances with add functionality
          DeviceInfoWidget(
            appliances: applianceProvider.appliances,
            onAddAppliance: applianceProvider.addAppliance,
          ),

          // Optional spacing at the bottom
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
