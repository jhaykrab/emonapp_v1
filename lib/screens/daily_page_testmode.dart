import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:Emon/widgets/time_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyPageTestMode extends StatefulWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped;

  const DailyPageTestMode({
    Key? key,
    required this.selectedTabIndex,
    required this.pageController,
    required this.setSelectedTabIndex,
    required this.onTimeButtonTapped,
  }) : super(key: key);

  @override
  State<DailyPageTestMode> createState() => _DailyPageTestModeState();
}

class _DailyPageTestModeState extends State<DailyPageTestMode> {
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  bool _isSendingData = false;
  bool _isDeleting = false;
  Timer? _dataTimer;
  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _loadSendingState();
    _loadHistoricalData(); // Load historical data when initialized
  }

  @override
  void dispose() {
    _dataTimer?.cancel(); // Safely cancel the timer if active
    super.dispose();
  }

  /// Loads historical data from Firestore.
  Future<void> _loadHistoricalData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('historical_data_testmode')
          .get();

      final loadedData = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'dateTime': doc.id,
              })
          .toList();

      if (mounted) {
        setState(() {
          _historicalData = loadedData;
        });
      }
    } catch (e) {
      debugPrint('Error loading historical data: $e');
    }
  }

  /// Load sending state from SharedPreferences
  Future<void> _loadSendingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isSending = prefs.getBool('isSendingData') ?? false;

    if (isSending) {
      _startContinuousDataSending(restart: true);
    }

    setState(() {
      _isSendingData = isSending;
    });
  }

  /// Save sending state to SharedPreferences
  Future<void> _saveSendingState(bool isSending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSendingData', isSending);
  }

  /// Start continuous data sending
  void _startContinuousDataSending({bool restart = false}) {
    if (!restart && _isSendingData) return;

    setState(() {
      _isSendingData = true;
    });

    _saveSendingState(true);

    _dataTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        await _sendContinuousData();
        debugPrint('Data sent successfully.');
      } catch (e) {
        debugPrint('Error sending data: $e');
      }
    });

    debugPrint('Continuous data sending started.');
  }

  /// Stop continuous data sending
  void _stopContinuousDataSending() {
    if (!_isSendingData) return;

    setState(() {
      _isSendingData = false;
    });

    _saveSendingState(false);

    _dataTimer?.cancel();
    debugPrint('Continuous data sending stopped.');
  }

  /// Sends energy consumption data to Firestore.
  Future<void> _sendContinuousData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not authenticated.');
      return;
    }

    final dbRef = FirebaseDatabase.instance.ref();
    const paths = ['SensorReadings', 'SensorReadings_2', 'SensorReadings_3'];

    double totalEnergy = 0.0;

    for (final path in paths) {
      final snapshot = await dbRef.child(path).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data['uid'] == user.uid) {
          totalEnergy += (data['energy'] ?? 0.0).toDouble();
        }
      }
    }

    if (mounted) {
      setState(() {
        _totalEnergy = totalEnergy;
        _isLoading = false;
      });

      final DateTime currentDateTime = DateTime.now();
      final String formattedDateTime =
          intl.DateFormat('yyyy-MM-dd_HH:mm:ss').format(currentDateTime);

      final String description = (totalEnergy <= 1)
          ? 'Low Energy Consumption'
          : 'Energy Usage Moderate to High';

      final historicalData = <String, dynamic>{
        'timestamp': currentDateTime,
        'totalEnergy': totalEnergy,
        'description': description,
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data_testmode')
            .doc(formattedDateTime)
            .set(historicalData, SetOptions(merge: true));

        debugPrint('Data sent successfully.');
        _loadHistoricalData();
      } catch (e) {
        debugPrint('Error storing data: $e');
      }
    }
  }

  /// Deletes all historical data from Firestore.
  Future<void> _deleteAllHistoricalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'Are you sure you want to delete all historical data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);

      try {
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data_testmode');

        final snapshot = await collection.get();
        final batch = FirebaseFirestore.instance.batch();

        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        setState(() {
          _historicalData.clear();
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All historical data deleted successfully.')),
        );
      } catch (e) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete historical data: $e')),
        );
      }
    }
  }

  /// Builds the historical data table card.
  Widget _buildEnergyDataCard(Map<String, dynamic> data) {
    final statusColor = data['description'] == 'Low Energy Consumption'
        ? Colors.green
        : Colors.orange;
    final statusIcon = data['description'] == 'Average Energy Consumption'
        ? Icons.check_circle_outline
        : Icons.warning_amber_outlined;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
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

  /// Builds the table header row.
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

  /// Builds a data row with a label and value.
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

  /// Builds a data row with an icon and description.
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
          const SizedBox(height: 20),
          TimeButtons(
            pageController: widget.pageController,
            selectedTabIndex: widget.selectedTabIndex,
            setSelectedTabIndex: widget.setSelectedTabIndex,
            onTimeButtonTapped: widget.onTimeButtonTapped,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: _historicalData.length,
              itemBuilder: (context, index) =>
                  _buildEnergyDataCard(_historicalData[index]),
            ),
          ),
          const SizedBox(height: 20),
          _buildControlButtons(),
          const SizedBox(height: 20),
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
            "Test Mode - Energy Data",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 54, 83, 56)),
          ),
        ],
      ),
    );
  }

  /// Builds Control Buttons
  Widget _buildControlButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start Button
            ElevatedButton(
              onPressed: !_isSendingData ? _startContinuousDataSending : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                    255, 54, 83, 56), // Dark green background
                foregroundColor: Colors.white, // White text
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // Smooth edges
                ),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('Begin'),
            ),
            const SizedBox(width: 20),
            // Stop Button
            OutlinedButton(
              onPressed: _isSendingData ? _stopContinuousDataSending : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: const Color.fromARGB(255, 54, 83, 56)!,
                    width: 2), // Dark green outline
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4), // Smooth edges
                ),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('End',
                  style:
                      TextStyle(color: const Color.fromARGB(255, 54, 83, 56))),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Delete All Button
        ElevatedButton(
          onPressed: _isDeleting ? null : _deleteAllHistoricalData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red background
            foregroundColor: Colors.white, // White text
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4), // Smooth edges
            ),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Delete All Data'),
        ),
      ],
    );
  }
}
