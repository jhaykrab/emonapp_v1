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
    'currentDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    'startDate': DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1))),
    'endDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
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

  /// Updates the current date and time every second.
  void _startDateTimeUpdater() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentWeekData['currentDate'] =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    });
  }

  void _loadRealTimeEnergy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Calculate the start and end of the week dynamically
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = now; // Current moment as end of the week for real-time

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

      // Set description based on total energy
      String energyDescription;
      if (totalEnergyFromWeek <= 50.0) {
        energyDescription = 'Low Weekly Energy Consumption';
      } else if (totalEnergyFromWeek > 50.0 && totalEnergyFromWeek <= 150.0) {
        energyDescription = 'Moderate Weekly Energy Consumption';
      } else {
        energyDescription = 'High Weekly Energy Consumption';
      }

      setState(() {
        _currentWeekEnergy = totalEnergyFromWeek;
        _currentWeekData = {
          'currentDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
          'startDate': DateFormat('yyyy-MM-dd').format(startOfWeek),
          'endDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(endOfWeek),
          'totalEnergy': _currentWeekEnergy,
          'description': energyDescription,
        };
      });
    } catch (e) {
      debugPrint('Error loading real-time energy: $e');
    }
  }

  /// Loads historical weekly data from Firestore.
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
        return {
          'startDate': doc['startDate'],
          'endDate': doc['endDate'],
          'totalEnergy': doc['totalEnergy'],
          'description': doc['description'],
        };
      }).toList();

      setState(() {
        _historicalWeeklyData = loadedData;
      });
    } catch (e) {
      debugPrint('Error loading weekly historical data: $e');
    }
  }

  Widget _buildWeeklyEnergyDataCard(Map<String, dynamic> data,
      {bool isCurrent = false}) {
    final statusColor = data['description'] == 'Low Weekly Energy Consumption'
        ? Colors.green
        : data['description'] == 'Moderate Weekly Energy Consumption'
            ? Colors.orange
            : Colors.red;

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
          TableRow(
            decoration:
                BoxDecoration(color: const Color.fromARGB(255, 147, 190, 142)),
            children: const [
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Text(
                  'Variables',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 32, 32, 32), // Dark green text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(6.0),
                child: Text(
                  'Values',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 32, 32, 32), // Dark green text
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          _buildTableDataRow('Current Date', data['currentDate']),
          _buildTableDataRow('Start Date', data['startDate']),
          _buildTableDataRow('End Date', data['endDate']),
          _buildTableDataRow(
              'Total Energy', '${data['totalEnergy'].toStringAsFixed(2)} kWh'),
          _buildTableDataRowWithIcon('Description', data['description'],
              Icons.info_outline, statusColor),
        ],
      ),
    );
  }

  TableRow _buildTableHeaderRow(Color backgroundColor) {
    return TableRow(
      decoration: BoxDecoration(color: backgroundColor),
      children: const [
        Padding(
          padding: EdgeInsets.all(6.0),
          child: Text(
            'Variables',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(6.0),
          child: Text(
            'Values',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
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

          // Current Week Data
          _buildWeeklyEnergyDataCard(_currentWeekData, isCurrent: true),
          const SizedBox(height: 30),

          // Historical Weekly Data
          Expanded(
            child: ListView.builder(
              itemCount: _historicalWeeklyData.length,
              itemBuilder: (context, index) {
                return _buildWeeklyEnergyDataCard(_historicalWeeklyData[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the header for the Daily Consumption section.
  Widget _buildHeader() {
    return Container(
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
            "Weekly Consumption",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 54, 83, 56),
            ),
          ),
        ],
      ),
    );
  }
}
