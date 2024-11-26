import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Local storage for tracking sent days
import 'package:Emon/widgets/time_buttons.dart';

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
  late Timer _dataTimer;
  bool _isSendingData = false;

  List<Map<String, dynamic>> _historicalData = [];
  Map<String, dynamic> _currentEnergyData = {
    'dateTime': intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    'totalEnergy': 0.0,
    'description': 'Initializing...',
  };

  @override
  void initState() {
    super.initState();
    _loadRealTimeData();
    _checkAndSendMissedDailyData(); // Handle missed data on app launch
    _startDailyDataSending(); // Schedule data sending for 11:59 PM
    _loadHistoricalData();
    _startDateTimeUpdater();
  }

  @override
  void dispose() {
    if (_isSendingData) {
      _dataTimer.cancel();
    }
    super.dispose();
  }

  /// Updates the current dateTime every second
  void _startDateTimeUpdater() {
    Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentEnergyData['dateTime'] =
            intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      });
    });
  }

  /// Checks for any missed days and sends data if needed
  Future<void> _checkAndSendMissedDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());

    // If no data has been sent for today, send it now
    if (!prefs.containsKey('lastSentDate') ||
        prefs.getString('lastSentDate') != today) {
      await _sendDailyData();
    }
  }

  /// Schedules daily data sending at 11:59 PM
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
        await _sendDailyData(); // Send daily data at 11:59 PM
        if (_isSendingData) scheduleNextDataSend(); // Schedule the next run
      });
    }

    scheduleNextDataSend();
  }

  /// Sends daily energy consumption data to Firestore
  Future<void> _sendDailyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentDateTime = DateTime.now();
    final today =
        intl.DateFormat('yyyy-MM-dd').format(currentDateTime); // Day-based ID
    final data = <String, dynamic>{
      'timestamp': currentDateTime,
      'totalEnergy': _totalEnergy, // Will be 0 if the device is off
      'description': _totalEnergy <= 1
          ? 'Low Energy Consumption'
          : 'Energy Usage Moderate to High',
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data')
          .doc(today) // Use the date as the document ID
          .set(data, SetOptions(merge: true));

      debugPrint('Daily data sent successfully for: $today');

      // Save the last sent date locally
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('lastSentDate', today);

      // Reload historical data after sending
      await _loadHistoricalData();
    } catch (e) {
      debugPrint('Error sending daily data: $e');
    }
  }

  /// Loads historical data from Firestore
  Future<void> _loadHistoricalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final loadedData = snapshot.docs.map((doc) {
          final data = doc.data();
          final totalEnergy = (data['totalEnergy'] ?? 0.0).toDouble();

          // Apply thresholds for description and color
          String description;
          Color statusColor;

          if (totalEnergy == 0) {
            description = 'No Energy Consumption';
            statusColor = Colors.grey;
          } else if (totalEnergy > 0 && totalEnergy <= 2) {
            description = 'Low Energy Consumption';
            statusColor = Colors.green;
          } else if (totalEnergy > 2 && totalEnergy <= 5) {
            description = 'Moderate Energy Consumption';
            statusColor = Colors.orange;
          } else if (totalEnergy > 5 && totalEnergy <= 7) {
            description = 'High Energy Consumption';
            statusColor = Colors.red;
          } else {
            description = 'Above Daily Limit'; // Handle values above 7
            statusColor = Colors.purple; // Optional for out-of-range values
          }

          return {
            'dateTime': doc.id, // Use document ID as dateTime
            'totalEnergy': totalEnergy,
            'description': description,
            'statusColor': statusColor,
          };
        }).toList();

        if (mounted) {
          setState(() => _historicalData = loadedData);
        }
      }
    } catch (e) {
      debugPrint('Error loading historical data: $e');
    }
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

        // Determine description and color based on energy thresholds
        String description;
        Color statusColor;

        if (totalEnergy == 0) {
          description = 'No Energy Consumption';
          statusColor = Colors.grey;
        } else if (totalEnergy > 0 && totalEnergy <= 2) {
          description = 'Low Energy Consumption';
          statusColor = Colors.green;
        } else if (totalEnergy > 2 && totalEnergy <= 5) {
          description = 'Moderate Energy Consumption';
          statusColor = Colors.orange;
        } else if (totalEnergy > 5 && totalEnergy <= 7) {
          description = 'High Energy Consumption';
          statusColor = Colors.red;
        } else {
          description = 'Above Daily Limit'; // Handle cases > 7
          statusColor = Colors.purple; // Optional: Add another color
        }

        if (mounted) {
          setState(() {
            _totalEnergy = totalEnergy;
            _currentEnergyData = {
              'dateTime':
                  intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
              'totalEnergy': _totalEnergy,
              'description': description,
              'statusColor': statusColor,
            };
          });
        }

        debugPrint('Real-time total energy updated: $_totalEnergy');
      } else {
        debugPrint('No data found in Firebase Realtime Database.');
      }
    });
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

  Widget _buildDailyEnergyDataCard(Map<String, dynamic> data) {
    final statusColor = data['statusColor'] as Color? ?? Colors.grey;
    final description = data['description'] ?? 'N/A';

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
                    fontWeight: FontWeight.normal,
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
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ), // Orange header row for real-time card
          _buildTableDataRow('Date & Time', data['dateTime'].toString()),
          _buildTableDataRow('Total Energy', '${data['totalEnergy']} kWh'),
          _buildTableDataRowWithIcon(
            'Description',
            description,
            Icons.bolt,
            statusColor,
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
          return _buildHistoricalEnergyDataCard(_historicalData[index]);
        },
      ),
    );
  }

  /// Builds the historical energy data table card with a dark green header row.
  Widget _buildHistoricalEnergyDataCard(Map<String, dynamic> data) {
    final statusColor = data['statusColor'] as Color? ?? Colors.grey;
    final description = data['description'] ?? 'N/A';

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
          _buildTableHeaderRow(const Color.fromARGB(255, 54, 83, 56)),
          _buildTableDataRow('Date & Time', data['dateTime'].toString()),
          _buildTableDataRow('Total Energy', '${data['totalEnergy']} kWh'),
          _buildTableDataRowWithIcon(
            'Description',
            description,
            Icons.bolt,
            statusColor,
          ),
        ],
      ),
    );
  }

  /// Helper method to build header rows with a configurable background color.
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
              fontWeight: FontWeight.normal,
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
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to build rows for the table.
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
}
