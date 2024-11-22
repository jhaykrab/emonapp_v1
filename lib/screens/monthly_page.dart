import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/time_buttons.dart';

class MonthlyPage extends StatefulWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped;

  const MonthlyPage({
    Key? key,
    required this.selectedTabIndex,
    required this.pageController,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped,
  }) : super(key: key);

  @override
  State<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  double _currentMonthEnergy = 0.0;
  late Timer _updateTimer;
  List<Map<String, dynamic>> _historicalMonthlyData = [];

  Map<String, dynamic> _currentMonthData = {
    'currentDate':
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString(),
    'startDate': DateFormat('yyyy-MM-dd')
        .format(DateTime(DateTime.now().year, DateTime.now().month, 1))
        .toString(),
    'endDate': DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime(
            DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59))
        .toString(),
    'totalEnergy': 0.0,
    'description': 'Initializing...',
  };

  @override
  void initState() {
    super.initState();
    _loadRealTimeMonthlyEnergy();
    _startDateTimeUpdater();
    _loadHistoricalMonthlyData();
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  void _startDateTimeUpdater() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentMonthData['currentDate'] =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()).toString();
      });
    });
  }

  void _loadRealTimeMonthlyEnergy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      double totalEnergyFromMonth = 0.0;

      for (var doc in snapshot.docs) {
        final dailyEnergy = (doc['totalEnergy'] ?? 0.0).toDouble();
        totalEnergyFromMonth += dailyEnergy;
      }

      String energyDescription = '';
      Color statusColor = Colors.grey;

      if (totalEnergyFromMonth == 0.0) {
        energyDescription = 'No Monthly Energy Consumption';
        statusColor = Colors.grey;
      } else if (totalEnergyFromMonth > 0.0 && totalEnergyFromMonth <= 70.0) {
        energyDescription = 'Low Energy Consumption';
        statusColor = Colors.green;
      } else if (totalEnergyFromMonth > 70.0 && totalEnergyFromMonth <= 141.0) {
        energyDescription = 'Moderate Energy Consumption';
        statusColor = Colors.orange;
      } else if (totalEnergyFromMonth > 141.0 &&
          totalEnergyFromMonth <= 211.0) {
        energyDescription = 'High Energy Consumption';
        statusColor = Colors.red;
      }

      if (mounted) {
        setState(() {
          _currentMonthEnergy = totalEnergyFromMonth;
          _currentMonthData = {
            'currentDate':
                DateFormat('yyyy-MM-dd HH:mm:ss').format(now).toString(),
            'startDate':
                DateFormat('yyyy-MM-dd').format(startOfMonth).toString(),
            'endDate': DateFormat('yyyy-MM-dd').format(endOfMonth).toString(),
            'totalEnergy': _currentMonthEnergy,
            'description': energyDescription,
            'statusColor': statusColor,
          };
        });
      }

      // Save to Firestore if the month ends
      if (now.isAfter(endOfMonth)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('monthly_historical_data')
            .doc(DateFormat('yyyy-MM').format(now))
            .set({
          'Date Started': startOfMonth,
          'Date Ended': endOfMonth,
          'Total Energy': _currentMonthEnergy,
          'Description': energyDescription,
        });
      }
    } catch (e) {
      debugPrint('Error loading real-time monthly energy: $e');
    }
  }

  Future<void> _loadHistoricalMonthlyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('monthly_historical_data')
          .get();

      final loadedData = snapshot.docs.map((doc) {
        final startDate =
            (doc['Date Started'] as Timestamp?)?.toDate() ?? DateTime.now();
        final endDate =
            (doc['Date Ended'] as Timestamp?)?.toDate() ?? DateTime.now();
        final totalEnergy = (doc['Total Energy'] ?? 0.0).toDouble();

        String energyDescription = '';
        Color statusColor = Colors.grey;

        if (totalEnergy == 0.0) {
          energyDescription = 'No Monthly Energy Consumption';
          statusColor = Colors.grey;
        } else if (totalEnergy > 0.0 && totalEnergy <= 70.0) {
          energyDescription = 'Low Energy Consumption';
          statusColor = Colors.green;
        } else if (totalEnergy > 70.0 && totalEnergy <= 141.0) {
          energyDescription = 'Moderate Energy Consumption';
          statusColor = Colors.orange;
        } else if (totalEnergy > 141.0 && totalEnergy <= 211.0) {
          energyDescription = 'High Energy Consumption';
          statusColor = Colors.red;
        }

        return {
          'startDate': DateFormat('yyyy-MM-dd').format(startDate).toString(),
          'endDate': DateFormat('yyyy-MM-dd').format(endDate).toString(),
          'totalEnergy': totalEnergy,
          'description': energyDescription,
          'statusColor': statusColor,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _historicalMonthlyData = loadedData;
        });
      }
    } catch (e) {
      debugPrint('Error loading monthly historical data: $e');
    }
  }

  Widget _buildMonthlyDataTable(Map<String, dynamic> data,
      {bool isCurrent = false}) {
    final statusColor = data['description'] == 'Low Monthly Energy Consumption'
        ? Colors.green
        : data['description'] == 'Moderate Monthly Energy Consumption'
            ? Colors.orange
            : data['description'] == 'High Monthly Energy Consumption'
                ? Colors.red
                : Colors.grey;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Table(
        border: TableBorder.all(
          color: const Color.fromARGB(255, 54, 83, 56),
          width: 0.5,
        ),
        columnWidths: const {
          0: FlexColumnWidth(0.8), // Adjusted for better spacing
          1: FlexColumnWidth(1.4),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color.fromARGB(
                      255, 147, 190, 142) // Light green for current table
                  : const Color.fromARGB(
                      255, 54, 83, 56), // Dark green for historical data
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  "Variables",
                  style: TextStyle(
                    fontSize: 12, // Reduced font size for mobile
                    color: isCurrent
                        ? const Color.fromARGB(255, 32, 32, 32)
                        : Colors.white,
                    fontWeight: FontWeight.normal, // Make the headers bold
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Text(
                  "Values",
                  style: TextStyle(
                    fontSize: 12, // Reduced font size for mobile
                    color: isCurrent
                        ? const Color.fromARGB(255, 32, 32, 32)
                        : Colors.white,
                    fontWeight: FontWeight.normal, // Make the headers bold
                  ),
                ),
              ),
            ],
          ),
          _buildTableDataRow('Current Date and Time', data['currentDate']),
          _buildTableDataRow('Start Date', data['startDate']),
          _buildTableDataRow('End Date', data['endDate']),
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

  TableRow _buildTableDataRow(String field, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0), // Reduced padding
          child: Text(
            field,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold), // Font size optimized for mobile
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0), // Reduced padding
          child: Text(
            value,
            style:
                const TextStyle(fontSize: 11), // Font size optimized for mobile
          ),
        ),
      ],
    );
  }

  TableRow _buildTableDataRowWithIcon(
      String field, String value, IconData icon, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(field,
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
          const SizedBox(height: 16),
          _buildMonthlyDataTable(_currentMonthData, isCurrent: true),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _historicalMonthlyData.length,
              itemBuilder: (context, index) {
                return _buildMonthlyDataTable(_historicalMonthlyData[index]);
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
            "Monthly Consumption",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 54, 83, 56)),
          ),
        ],
      ),
    );
  }
}
