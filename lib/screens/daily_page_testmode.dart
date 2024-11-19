import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:Emon/widgets/time_buttons.dart';
import 'package:Emon/screens/daily_page.dart';

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
  State<DailyPageTestMode> createState() =>
      _DailyPageTestModeState(); //Corrected
}

class _DailyPageTestModeState extends State<DailyPageTestMode> {
  //Corrected
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  bool _isSendingData = false;
  bool _isDeleting = false;
  late Timer _dataTimer;
  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _dataTimer.cancel();
    super.dispose();
  }

  void _startContinuousDataSending() {
    if (_isSendingData) return;

    _isSendingData = true;

    _dataTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref();
        final paths = [
          'SensorReadings',
          'SensorReadings_2',
          'SensorReadings_3'
        ];

        double totalEnergy = 0;

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

          DateTime currentDateTime = DateTime.now();
          String formattedDateTime =
              intl.DateFormat('yyyy-MM-dd_HH:mm:ss').format(currentDateTime);

          String description = (totalEnergy <= 1)
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

            _loadHistoricalData();
          } catch (e) {
            print('Error storing data: $e');
          }
        }
      }
    });
  }

  void _stopContinuousDataSending() {
    if (!_isSendingData) return;

    _isSendingData = false;
    _dataTimer.cancel();
  }

  Future<void> _loadHistoricalData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data_testmode')
            .get();

        if (snapshot.docs.isNotEmpty) {
          List<Map<String, dynamic>> loadedData = [];

          for (var doc in snapshot.docs) {
            String dateTime = doc.id;

            final subDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('historical_data_testmode')
                .doc(dateTime)
                .get();

            if (subDoc.exists) {
              Map<String, dynamic> data = subDoc.data()!;
              data['dateTime'] = dateTime;
              loadedData.add(data);
            }
          }

          if (mounted) {
            setState(() {
              _historicalData = loadedData;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading historical data: $e');
    }
  }

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
      setState(() {
        _isDeleting = true;
      });

      try {
        final collection = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data_testmode');

        final snapshot = await collection.get();

        WriteBatch batch = FirebaseFirestore.instance.batch();

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
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete historical data: $e')),
        );
      }
    }
  }

  Widget _buildEnergyDataCard(Map<String, dynamic> data) {
    // Define the color and icon based on the description
    Color statusColor;
    IconData statusIcon;

    if (data['description'] == 'Low Energy Consumption') {
      statusColor = Colors.green; // Green for low consumption
      statusIcon = Icons.check_circle_outline; // Checkmark icon
    } else {
      statusColor = Colors.orange; // Orange for moderate/high consumption
      statusIcon = Icons.warning_amber_outlined; // Warning icon
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: SizedBox(
          width: 320, // Consistent width
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
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 54, 83, 56),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      'Variables',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      'Values',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      'Date & Time',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      data['dateTime'],
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      'Total Energy',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text('${data['totalEnergy']} kWh',
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Text(
                      'Description',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: statusColor,
                          size: 14, // Small icon size for better alignment
                        ),
                        const SizedBox(width: 5),
                        Text(
                          data['description'],
                          style: TextStyle(fontSize: 11, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            // Use a Container instead of OutlinedButton
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
                Text("Daily Consumption",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(
                            255, 54, 83, 56))), // Text with color
              ],
            ),
          ),
          SizedBox(height: 30),

          // Add TimeButtons widget here
          TimeButtons(
            pageController: widget.pageController,
            selectedTabIndex: widget.selectedTabIndex,
            setSelectedTabIndex: widget.setSelectedTabIndex,
            onTimeButtonTapped: widget.onTimeButtonTapped,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DailyPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 54, 83, 56),
              foregroundColor: const Color(0xFFe8f5e9),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 12),
                Text('Switch to Scheduled Mode'),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildEnergyDataCard({
            'dateTime':
                DateFormat('yyyy-MM-dd_HH:mm:ss').format(DateTime.now()),
            'totalEnergy': _totalEnergy,
            'description': _totalEnergy <= 1
                ? 'Low Energy Consumption'
                : 'Energy Usage Moderate to High'
          }),
          const Divider(height: 20),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 320, // Explicitly match the desired width
                child: ListView.builder(
                  itemCount: _historicalData.length,
                  itemBuilder: (context, index) {
                    var data = _historicalData[index];
                    return _buildEnergyDataCard(data);
                  },
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isSendingData
                    ? null
                    : () {
                        _startContinuousDataSending();
                      },
                child: const Text('Start Sending Data'),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: !_isSendingData
                    ? null
                    : () {
                        _stopContinuousDataSending();
                      },
                child: const Text('Pause Sending Data'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isDeleting ? null : _deleteAllHistoricalData,
                child: _isDeleting
                    ? const CircularProgressIndicator()
                    : const Text('Delete All Data'),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ],
      ),
    );
  }
}
