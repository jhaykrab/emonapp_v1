import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:Emon/widgets/app_bar_widget.dart'; // Import AppBarWidget
import 'package:Emon/widgets/bottom_nav_bar_widget.dart'; // Import BottomNavBarWidget

class RealTimeAnalyticsPage extends StatefulWidget {
  const RealTimeAnalyticsPage({Key? key}) : super(key: key);

  @override
  _RealTimeAnalyticsPageState createState() => _RealTimeAnalyticsPageState();
}

class _RealTimeAnalyticsPageState extends State<RealTimeAnalyticsPage> {
  final DatabaseReference _realtimeRef =
      FirebaseDatabase.instance.ref('SensorReadings');
  double _totalEnergy = 0.0;
  List<FlSpot> _graphData = [];
  FlSpot? mostLeftSpot; // Make `mostLeftSpot` nullable.
  int _selectedNavbarIndex =
      3; // Set to 3 for the History tab in the bottom navbar

  @override
  void initState() {
    super.initState();
    mostLeftSpot = FlSpot(0, 0); // Provide a default value.
    _listenToRealtimeData();
  }

  void _updateGraphData() {
    if (_graphData.isNotEmpty) {
      mostLeftSpot = _graphData.reduce((a, b) => a.x < b.x ? a : b);
    } else {
      // Set to null if `_graphData` is empty.
      mostLeftSpot = null;
    }
  }

  void _listenToRealtimeData() {
    _realtimeRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final double energy = (data['energy_kWh'] ?? 0.0).toDouble();
        final now = DateTime.now();

        setState(() {
          _totalEnergy = energy;

          // Add data to graph.
          _graphData.add(
            FlSpot(now.hour + now.minute / 60, energy),
          );

          // Keep only the last 24 hours of data.
          _graphData = _graphData.where((spot) {
            return now
                    .difference(DateTime(
                      now.year,
                      now.month,
                      now.day,
                      spot.x.toInt(),
                      ((spot.x - spot.x.toInt()) * 60).toInt(),
                    ))
                    .inHours <=
                24;
          }).toList();

          // Update `mostLeftSpot`.
          _updateGraphData();
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeRef.onDisconnect();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedNavbarIndex = index;
      // Add any navigation logic if needed for other BottomNavigationBar items.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
          userName: 'User Full Name'), // Using AppBarWidget from HistoryScreen
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            const Text(
              "Real-Time Energy Consumption",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Gauge Widget
            _buildGaugeWidget(),

            const SizedBox(height: 20),

            // Line Graph
            Expanded(
              child: _buildLineGraph(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedNavbarIndex,
        onItemTapped: _onItemTapped,
      ), // Using BottomNavBarWidget from HistoryScreen
    );
  }

  Widget _buildGaugeWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "${_totalEnergy.toStringAsFixed(3)} kWh",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Current Energy Consumption",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLineGraph() {
    return Flexible(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align title to the left
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4.0), // Add left padding to title
            child: Text(
              "Energy Consumption Over Time",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 24,
                    left: 8,
                    right:
                        8), // Increased bottom padding for x-axis labels, adjusted others
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _graphData,
                        isCurved: true,
                        barWidth: 3,
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.lightBlueAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.3),
                              Colors.lightBlueAccent.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: 24,
                    minY: 0,
                    maxY: 3,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          "kWh", // Shortened label
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 8),
                            );
                          },
                          reservedSize: 20,
                          interval: 0.5,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          "Time",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final hour = value.toInt();
                            final time = TimeOfDay(hour: hour, minute: 0);

                            // Check if it's 12:00 AM (0) and return an empty SizedBox
                            if (hour == 0) {
                              return const SizedBox.shrink();
                            }

                            return Transform.rotate(
                              angle: -0.7854,
                              child: Text(
                                time.format(context),
                                style: const TextStyle(fontSize: 8),
                              ),
                            );
                          },
                          interval: 2,
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                            color: Colors.grey
                                .withOpacity(0.5))), // Added a border
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false, // Remove vertical lines
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
