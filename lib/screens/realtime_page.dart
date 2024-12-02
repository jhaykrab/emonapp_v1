import 'package:flutter/material.dart';
import 'package:Emon/widgets/gauge_widget.dart'; // Import updated GaugeWidget
import 'package:Emon/widgets/device_info_widget.dart';
import 'package:provider/provider.dart';
import 'package:Emon/providers/appliance_provider.dart';
import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:Emon/widgets/time_buttons.dart'; // Import TimeButtons
import 'package:Emon/screens/dashboard_screen.dart'; // Import DashboardScreen for GlobalKey

class RealTimePage extends StatelessWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped;

  const RealTimePage({
    Key? key,
    required this.selectedTabIndex,
    required this.pageController,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final applianceProvider = Provider.of<ApplianceProvider>(context);

    // Aggregate energy data from all appliances
    final double totalEnergy = applianceProvider.appliances.fold(
      0.0,
      (sum, appliance) => sum + appliance.energy,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(255, 54, 83, 56),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.bolt, color: Color.fromARGB(255, 231, 175, 22)),
                SizedBox(width: 8),
                Text(
                  "Realtime Consumption",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 54, 83, 56),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Pass the aggregated energy to the GaugeWidget
          GaugeWidget(
              energy: totalEnergy), // Pass the totalEnergy to GaugeWidget
          const SizedBox(height: 20),
          TimeButtons(
            pageController: pageController,
            selectedTabIndex: selectedTabIndex,
            setSelectedTabIndex: setSelectedTabIndex,
            onTimeButtonTapped: onTimeButtonTapped,
          ),
          DeviceInfoWidget(
            appliances: applianceProvider.appliances,
            onAddAppliance: applianceProvider.addAppliance,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
