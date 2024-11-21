import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:Emon/widgets/time_buttons.dart';
import 'package:Emon/screens/daily_page_testmode.dart';

class DailyPage extends StatefulWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped;

  const DailyPage({
    Key? key,
    required this.selectedTabIndex,
    required this.pageController,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped,
  }) : super(key: key);

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
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
    _startDailyDataSending();
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

  /// Updates the current dateTime value every second.
  void _startDateTimeUpdater() {
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentEnergyData['dateTime'] =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    });
  }

  /// Loads real-time data from Firebase Realtime Database and sums the energy readings.
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

        setState(() {
          _totalEnergy = totalEnergy;
          _currentEnergyData = {
            'dateTime':
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            'totalEnergy': _totalEnergy,
            'description': _totalEnergy <= 1
                ? 'Low Energy Consumption'
                : 'Energy Usage Moderate to High',
          };
        });
      }
    });
  }

  /// Schedules daily data sending at 11:59 PM.
  void _startDailyDataSending() {
    if (_isSendingData) return;
    _isSendingData = true;

    void scheduleNextDataSend() {
      final now = DateTime.now();
      final nextRunTime = DateTime(now.year, now.month, now.day, 23, 59).add(
        now.isAfter(DateTime(now.year, now.month, now.day, 23, 59))
            ? const Duration(days: 1)
            : Duration.zero,
      );
      final durationUntilNextRun = nextRunTime.difference(now);

      _dataTimer = Timer(durationUntilNextRun, () async {
        await _sendDailyData();
        if (_isSendingData) scheduleNextDataSend();
      });
    }

    scheduleNextDataSend();
  }

  /// Sends daily energy consumption data to Firestore.
  Future<void> _sendDailyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentDateTime = DateTime.now();
    final formattedDateTime =
        intl.DateFormat('yyyy-MM-dd_HH:mm:ss').format(currentDateTime);

    final data = <String, dynamic>{
      'timestamp': currentDateTime,
      'totalEnergy': _totalEnergy,
      'description': _totalEnergy <= 1
          ? 'Low Energy Consumption'
          : 'Energy Usage Moderate to High',
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data')
          .doc(formattedDateTime)
          .set(data, SetOptions(merge: true));

      _loadHistoricalData();
    } catch (e) {
      debugPrint('Error sending daily data: $e');
    }
  }

  /// Loads historical data from Firestore.
  Future<void> _loadHistoricalData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final loadedData = snapshot.docs.map((doc) {
          final data = doc.data();
          data['dateTime'] = doc.id;
          return data;
        }).toList();

        if (mounted) {
          setState(() => _historicalData = loadedData);
        }
      }
    } catch (e) {
      debugPrint('Error loading historical data: $e');
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
          _buildDailyEnergyDataCard(_currentEnergyData),
          const SizedBox(height: 30),
          _buildEnergyDataList(),
        ],
      ),
    );
  }

  /// Builds the daily energy data table card.
  Widget _buildDailyEnergyDataCard(Map<String, dynamic> data) {
    final statusColor = data['description'] == 'Low Energy Consumption'
        ? Colors.green
        : Colors.orange;
    final statusIcon = data['description'] == 'Low Energy Consumption'
        ? Icons.check_circle_outline
        : Icons.warning_amber_outlined;

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
          _buildTableDataRow('Date & Time', data['dateTime']),
          _buildTableDataRow('Total Energy', '${data['totalEnergy']} kWh'),
          _buildTableDataRowWithIcon(
            'Description',
            data['description'],
            statusIcon,
            statusColor,
          ),
        ],
      ),
    );
  }

  /// Builds a data row with an icon and description (for description with icon).
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
            "Daily Consumption",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 54, 83, 56),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the historical energy data list.
  Widget _buildEnergyDataList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _historicalData.length,
        itemBuilder: (context, index) {
          return _buildDailyEnergyDataCard(_historicalData[index]);
        },
      ),
    );
  }

  /// Helper method to build rows for the table.
  TableRow _buildTableHeaderRow() {
    return const TableRow(
      decoration: BoxDecoration(color: Color.fromARGB(255, 54, 83, 56)),
      children: [
        Padding(
          padding: EdgeInsets.all(6.0),
          child: Text(
            'Variables',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(6.0),
          child: Text(
            'Values',
            style: TextStyle(fontSize: 12, color: Colors.white),
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
}
