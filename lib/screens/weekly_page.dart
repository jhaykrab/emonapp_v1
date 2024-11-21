import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
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
  double _totalEnergy = 0.0;
  late Timer _updateTimer;
  late Timer _dataTimer;
  late Timer _timeUpdateTimer;
  bool _isSendingData = false;
  List<Map<String, dynamic>> _historicalData = [];

  Map<String, dynamic> _currentEnergyData = {
    'dateTime': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    'totalEnergy': 0.0,
    'description': 'Initializing...',
  };

  @override
  void initState() {
    super.initState();
    _loadRealTimeData();
    _startWeeklyDataSending();
    _loadHistoricalData();
    _startDateTimeUpdater();
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    if (_isSendingData) {
      _dataTimer.cancel();
    }
    _timeUpdateTimer.cancel();
    super.dispose();
  }

  void _startDateTimeUpdater() {
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentEnergyData['dateTime'] =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    });
  }

  void _loadRealTimeData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbRef = FirebaseDatabase.instance.ref();
    const paths = ['SensorReadings', 'SensorReadings_2', 'SensorReadings_3'];

    dbRef.child('/').onValue.listen((event) {
      final allData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (allData != null) {
        double totalEnergy = 0.0;

        for (var path in paths) {
          final sensorData = allData[path] as Map<dynamic, dynamic>?;

          if (sensorData != null && sensorData['uid'] == user.uid) {
            totalEnergy += (sensorData['energy'] ?? 0.0).toDouble();
          }
        }

        final status = _getEnergyStatus(totalEnergy);
        final statusColor = _getStatusColor(status);
        final statusIcon = _getStatusIcon(status);

        if (mounted) {
          // Check if the widget is still mounted
          setState(() {
            _totalEnergy = totalEnergy;
            _currentEnergyData = {
              'dateTime':
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
              'totalEnergy': _totalEnergy,
              'description': status,
              'statusColor': statusColor,
              'statusIcon': statusIcon,
            };
          });
        }
      }
    });
  }

// Function to determine the energy status description based on the energy value
  String _getEnergyStatus(double energy) {
    if (energy == 0) {
      return 'No Energy Consumption yet for this week';
    } else if (energy <= 16.33) {
      return 'Low Energy Consumption';
    } else if (energy <= 32.67) {
      return 'Moderate Energy Consumption';
    } else {
      return 'High Energy Consumption';
    }
  }

// Function to return the corresponding color based on the energy status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'No Energy Consumption yet for this week':
        return Colors.grey; // Grey for no consumption
      case 'Low Energy Consumption':
        return Colors.green; // Green for low consumption
      case 'Moderate Energy Consumption':
        return Colors.orange; // Orange for moderate consumption
      case 'High Energy Consumption':
        return Colors.red; // Red for high consumption
      default:
        return Colors.grey; // Default color for unknown status
    }
  }

// Function to return the corresponding icon based on the energy status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'No Energy Consumption yet for this week':
        return Icons.power_off; // Icon for no energy consumption
      case 'Low Energy Consumption':
        return Icons.check_circle_outline; // Icon for low consumption
      case 'Moderate Energy Consumption':
        return Icons.warning_amber_outlined; // Icon for moderate consumption
      case 'High Energy Consumption':
        return Icons.error_outline; // Icon for high consumption
      default:
        return Icons.help_outline; // Default icon for unknown status
    }
  }

  void _startWeeklyDataSending() {
    if (_isSendingData) return;
    _isSendingData = true;

    void scheduleNextDataSend() {
      final now = DateTime.now();
      final nextSunday =
          now.add(Duration(days: (7 - now.weekday) % 7)); // Next Sunday
      final nextRunTime =
          DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 23, 59);

      final durationUntilNextRun = nextRunTime.difference(now);

      _dataTimer = Timer(durationUntilNextRun, () async {
        await _sendWeeklyData();
        if (_isSendingData) scheduleNextDataSend();
      });
    }

    scheduleNextDataSend();
  }

  Future<void> _sendWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentDateTime = DateTime.now();
    final formattedDateTime =
        intl.DateFormat('yyyy-MM-dd_HH:mm:ss').format(currentDateTime);

    final data = <String, dynamic>{
      'timestamp': currentDateTime,
      'totalEnergy': _totalEnergy,
      'description': _totalEnergy <= 49
          ? 'Low Weekly Energy Consumption'
          : _totalEnergy <= 98
              ? 'Moderate Weekly Energy Consumption'
              : 'High Weekly Energy Consumption',
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data_weekly')
          .doc(formattedDateTime)
          .set(data, SetOptions(merge: true));

      _loadHistoricalData();
    } catch (e) {
      debugPrint('Error sending weekly data: $e');
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data_weekly')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final loadedData = snapshot.docs.map((doc) {
          final data = doc.data();
          data['dateTime'] = doc.id;
          return data;
        }).toList();

        if (mounted) {
          // Check if the widget is still mounted
          setState(() => _historicalData = loadedData);
        }
      }
    } catch (e) {
      debugPrint('Error loading historical data: $e');
    }
  }

  TableRow _buildTableDataRowWithWeekRange() {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Start of this week
    final endOfWeek = startOfWeek.add(Duration(days: 6)); // End of this week

    // Format the start and end dates
    final startFormatted = DateFormat('EEEE, MMM d, yyyy').format(startOfWeek);
    final endFormatted = DateFormat('EEEE, MMM d, yyyy').format(endOfWeek);

    // Get the week number in the month
    final weekNumber = ((now.day - 1) ~/ 7) + 1;
    final weekOfMonth =
        "$weekNumber${_getOrdinalSuffix(weekNumber)} Week of ${DateFormat('MMMM').format(now)}";

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            'Date Started:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            startFormatted,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableDataRowWithWeekEnd() {
    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Start of this week
    final endOfWeek = startOfWeek.add(Duration(days: 6)); // End of this week

    // Format the start and end dates
    final startFormatted = DateFormat('EEEE, MMM d, yyyy').format(startOfWeek);
    final endFormatted = DateFormat('EEEE, MMM d, yyyy').format(endOfWeek);

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            'Date Ends in:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            endFormatted,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableDataRowWithWeekDescription() {
    final now = DateTime.now();
    final weekNumber = ((now.day - 1) ~/ 7) + 1;
    final weekOfMonth =
        "$weekNumber${_getOrdinalSuffix(weekNumber)} Week of ${DateFormat('MMMM').format(now)} - current";

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            'Week of the Month:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            weekOfMonth,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
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
          _buildWeeklyEnergyDataCard(_currentEnergyData),
          const SizedBox(height: 30),
          _buildEnergyDataList(),
        ],
      ),
    );
  }

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

  Widget _buildWeeklyEnergyDataCard(Map<String, dynamic> data) {
    final status = data['description'];
    final statusColor =
        _getStatusColor(status); // Get the color based on the status
    final statusIcon =
        _getStatusIcon(status); // Get the icon based on the status

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
          _buildTableHeaderRow(),
          _buildTableDataRowWithWeekRange(),
          _buildTableDataRowWithWeekEnd(),
          _buildTableDataRowWithWeekDescription(),
          _buildTableDataRow('Total Energy', '${data['totalEnergy']} kWh'),
          _buildTableDataRowWithIcon(
            'Description',
            status,
            statusIcon,
            statusColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyDataList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _historicalData.length,
        itemBuilder: (context, index) {
          return _buildWeeklyEnergyDataCard(_historicalData[index]);
        },
      ),
    );
  }

  TableRow _buildTableHeaderRow() {
    return TableRow(
      decoration:
          const BoxDecoration(color: const Color.fromARGB(255, 54, 83, 56)),
      children: [
        const Padding(
          padding: EdgeInsets.all(6.0),
          child: Text(
            'Variables',
            style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
                color: Colors.white),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(6.0),
          child: Text(
            'Values',
            style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12,
                color: Colors.white),
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
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            value,
            style: const TextStyle(fontSize: 11),
          ),
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
              Icon(icon, size: 16, color: color), // Icon color based on status
              const SizedBox(width: 5),
              Text(value,
                  style: TextStyle(
                      fontSize: 11,
                      color: color)), // Text color based on status
            ],
          ),
        ),
      ],
    );
  }
}
