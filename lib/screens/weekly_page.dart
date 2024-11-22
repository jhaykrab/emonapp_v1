import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/time_buttons.dart';

class WeeklyPage extends StatefulWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped;

  const WeeklyPage({
    Key? key,
    required this.selectedTabIndex,
    required this.pageController,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped,
  }) : super(key: key);

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage> {
  double _currentWeekEnergy = 0.0;
  late Timer _updateTimer;
  List<Map<String, dynamic>> _historicalWeeklyData = [];

  Map<String, dynamic> _currentWeekData = {
    'currentDate':
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString(),
    'startDate': DateFormat('yyyy-MM-dd')
        .format(
            DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))
        .toString(),
    'endDate':
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString(),
    'totalEnergy': 0.0,
    'description': 'Initializing...',
  };

  @override
  void initState() {
    super.initState();
    _loadRealTimeEnergy();
    _startDateTimeUpdater();
    _loadHistoricalWeeklyData();
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  void _startDateTimeUpdater() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentWeekData['currentDate'] =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString();
      });
    });
  }

  void _loadRealTimeEnergy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = now;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      double totalEnergyFromWeek = 0.0;

      for (var doc in snapshot.docs) {
        final dailyEnergy = (doc['totalEnergy'] ?? 0.0).toDouble();
        totalEnergyFromWeek += dailyEnergy;
      }

      String energyDescription = '';
      Color statusColor = Colors.grey;

      // Update the conditions
      if (totalEnergyFromWeek == 0.0) {
        energyDescription = 'No Weekly Energy Consumption';
        statusColor = Colors.grey;
      } else if (totalEnergyFromWeek > 0.001 && totalEnergyFromWeek <= 16.33) {
        energyDescription = 'Low Weekly Energy Consumption';
        statusColor = Colors.green;
      } else if (totalEnergyFromWeek > 16.33 && totalEnergyFromWeek <= 32.66) {
        energyDescription = 'Moderate Weekly Energy Consumption';
        statusColor = Colors.orange;
      } else if (totalEnergyFromWeek > 32.66 && totalEnergyFromWeek <= 49.0) {
        energyDescription = 'High Weekly Energy Consumption';
        statusColor = Colors.red;
      }

      if (mounted) {
        setState(() {
          _currentWeekEnergy = totalEnergyFromWeek;
          _currentWeekData = {
            'currentDate':
                DateFormat('yyyy-MM-dd HH:mm:ss').format(now).toString(),
            'startDate':
                DateFormat('yyyy-MM-dd').format(startOfWeek).toString(),
            'endDate': DateFormat('yyyy-MM-dd').format(endOfWeek).toString(),
            'totalEnergy': _currentWeekEnergy,
            'description': energyDescription,
            'statusColor': statusColor,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading real-time energy: $e');
    }
  }

  Future<void> _loadHistoricalWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weekly_historical_data')
          .get();

      final loadedData = snapshot.docs.map((doc) {
        final startDate =
            (doc['Start Date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final endDate =
            (doc['End Date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final totalEnergy = (doc['totalEnergy'] ?? 0.0).toDouble();

        // Dynamically determine description and statusColor
        String energyDescription = '';
        Color statusColor = Colors.grey;

        if (totalEnergy == 0.0) {
          energyDescription = 'No Weekly Energy Consumption';
          statusColor = Colors.grey;
        } else if (totalEnergy > 0.0 && totalEnergy <= 16.33) {
          energyDescription = 'Low Energy Consumption';
          statusColor = Colors.green;
        } else if (totalEnergy > 16.33 && totalEnergy <= 32.66) {
          energyDescription = 'Moderate Energy Consumption';
          statusColor = Colors.orange;
        } else if (totalEnergy > 32.66 && totalEnergy <= 49.0) {
          energyDescription = 'High Energy Consumption';
          statusColor = Colors.red;
        }

        return {
          'startDate': DateFormat('yyyy-MM-dd').format(startDate).toString(),
          'endDate': DateFormat('yyyy-MM-dd').format(endDate).toString(),
          'totalEnergy': totalEnergy,
          'description': energyDescription,
          'statusColor': statusColor, // Dynamically assigned
        };
      }).toList();

      if (mounted) {
        setState(() {
          _historicalWeeklyData = loadedData;
        });
      }
    } catch (e) {
      debugPrint('Error loading weekly historical data: $e');
    }
  }

  Widget _buildWeeklyEnergyDataCard(Map<String, dynamic> data,
      {bool isCurrent = false, bool isHistorical = false}) {
    final statusColor = data['description'] == 'Low Weekly Energy Consumption'
        ? Colors.green
        : data['description'] == 'Moderate Weekly Energy Consumption'
            ? Colors.orange
            : data['description'] == 'High Weekly Energy Consumption'
                ? Colors.red
                : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Table(
        border: TableBorder.all(
          color: const Color.fromARGB(255, 54, 83, 56),
          width: 0.5,
          borderRadius: BorderRadius.circular(5),
        ),
        columnWidths: const {
          0: FlexColumnWidth(0.8),
          1: FlexColumnWidth(1.4),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildTableHeaderRow(
            isHistorical
                ? const Color.fromARGB(
                    255, 54, 83, 56) // Dark green for historical tables
                : const Color.fromARGB(
                    255, 147, 190, 142), // Default color for real-time table
            isHistorical: isHistorical,
          ),
          if (isCurrent)
            _buildTableDataRow('Current Date', data['currentDate'] ?? 'N/A'),
          _buildTableDataRow('Start Date', data['startDate'] ?? 'N/A'),
          _buildTableDataRow('End Date', data['endDate'] ?? 'N/A'),
          _buildTableDataRow('Total Energy',
              '${(data['totalEnergy'] ?? 0.0).toStringAsFixed(2)} kWh'),
          _buildTableDataRowWithIcon(
              'Description',
              data['description'] ?? 'N/A',
              Icons.check_circle_outline,
              statusColor),
        ],
      ),
    );
  }

  TableRow _buildTableHeaderRow(Color backgroundColor,
      {bool isHistorical = false}) {
    return TableRow(
      decoration: BoxDecoration(color: backgroundColor),
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            'Variables',
            style: TextStyle(
              fontSize: 12,
              color: isHistorical
                  ? Colors.white // White text for historical tables
                  : const Color.fromARGB(255, 32, 32, 32), // Default color
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            'Values',
            style: TextStyle(
              fontSize: 12,
              color: isHistorical
                  ? Colors.white // White text for historical tables
                  : const Color.fromARGB(255, 32, 32, 32), // Default color
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableDataRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(value, style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  TableRow _buildTableDataRowWithIcon(
      String label, String value, IconData icon, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(value, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 30),
          TimeButtons(
            pageController: widget.pageController,
            selectedTabIndex: widget.selectedTabIndex,
            setSelectedTabIndex: widget.setSelectedTabIndex,
            onTimeButtonTapped: widget.onTimeButtonTapped,
          ),
          const SizedBox(height: 20),
          _buildWeeklyEnergyDataCard(_currentWeekData, isCurrent: true),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _historicalWeeklyData.length,
              itemBuilder: (context, index) {
                return _buildWeeklyEnergyDataCard(
                  _historicalWeeklyData[index],
                  isHistorical: true, // Mark as historical
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color.fromARGB(255, 54, 83, 56), width: 2.0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.bolt, color: Color.fromARGB(255, 231, 175, 22)),
          SizedBox(width: 8),
          Text(
            "Weekly Consumption",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 54, 83, 56)),
          ),
        ],
      ),
    );
  }
}
