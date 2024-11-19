import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/time_buttons.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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
  Timer? _storageTimer;
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  late StreamSubscription<DatabaseEvent> _energySubscription;

  List<Map<String, dynamic>> _historicalData = [];

  @override
  void initState() {
    super.initState();
    _listenForEnergyChanges();
    _loadHistoricalData();
  }

  @override
  void dispose() {
    _energySubscription.cancel();
    super.dispose();
  }

  void _listenForEnergyChanges() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final dbRef = FirebaseDatabase.instance.ref();
        final paths = [
          'SensorReadings',
          'SensorReadings_2',
          'SensorReadings_3'
        ];

        _energySubscription = dbRef.onValue.listen((DatabaseEvent event) async {
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
          }
        });
      }
    } catch (e) {
      print('Error fetching total energy: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scheduleDataStorage(String userId) {
    // Cancel any existing timer to prevent multiple timers
    _storageTimer?.cancel();

    _storageTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      double totalEnergy = await _calculateTotalEnergy(userId);
      final historicalData = <String, dynamic>{
        'timestamp': DateTime.now(),
        'totalEnergy': totalEnergy,
      };

      try {
        String dateString =
            intl.DateFormat('yyyy-MM-dd-HH-mm-ss').format(DateTime.now());

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('historical_data')
            .doc(dateString)
            .collection('all_appliances')
            .doc('data')
            .set(historicalData, SetOptions(merge: true));

        print('Data stored successfully!');
        _loadHistoricalData(); // Refresh UI
      } catch (e) {
        print('Error storing data: $e');
      }
    });
  }

  Future<double> _calculateTotalEnergy(String userId) async {
    final dbRef = FirebaseDatabase.instance.ref();
    final paths = ['SensorReadings', 'SensorReadings_2', 'SensorReadings_3'];
    double totalEnergy = 0;
    for (final path in paths) {
      final snapshot = await dbRef.child(path).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data['uid'] == userId) {
          totalEnergy += (data['energy'] ?? 0.0).toDouble();
        }
      }
    }
    return totalEnergy;
  }

  Future<void> _resetHistoricalData() async {
    try {
      _storageTimer?.cancel();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final instance = FirebaseFirestore.instance;
        final collection = instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data');
        final snapshot = await collection.get();
        for (var doc in snapshot.docs) {
          await collection.doc(doc.id).delete();
        }
        setState(() {
          _historicalData = [];
        });
        print("Historical data reset successfully!");
      }
    } catch (e) {
      print("Error resetting historical data: $e");
    }
  }

  Future<void> _clearTestDataFromFirestore() async {
    // New function
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final instance = FirebaseFirestore.instance;
        final collection = instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data');

        // Get all documents in 'historical_data'
        final snapshot = await collection.get();

        // Delete each document
        for (var doc in snapshot.docs) {
          await collection.doc(doc.id).delete();
        }

        setState(() {
          _historicalData = [];
        });

        print('Test data cleared from Firestore successfully!');
      }
    } catch (e) {
      print('Error clearing test data: $e');
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('historical_data')
            .get();

        if (mounted) {
          setState(() {
            _historicalData = snapshot.docs
                .map((doc) {
                  String date = doc.id;
                  CollectionReference allAppliancesRef = FirebaseFirestore
                      .instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('historical_data')
                      .doc(date)
                      .collection('all_appliances');
                  return allAppliancesRef
                      .doc('data')
                      .get()
                      .then((subcollectionDoc) {
                    if (subcollectionDoc.exists) {
                      Map<String, dynamic> subcollectionData =
                          subcollectionDoc.data() as Map<String, dynamic>;
                      subcollectionData['date'] = date;
                      return subcollectionData;
                    }
                    return null;
                  });
                })
                .whereType<Map<String, dynamic>>()
                .toList();
          });
        }
      }
    } on Exception catch (e) {
      print('Error loading historical data: $e');
    }
  }

  DateTime startOfDay(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  Widget _buildCurrentEnergyCard() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("User not logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyEnergy')
          .where('timestamp',
              isGreaterThanOrEqualTo: startOfDay(DateTime.now()))
          .where('timestamp',
              isLessThan:
                  startOfDay(DateTime.now().add(const Duration(days: 1))))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        double totalEnergy = 0;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            totalEnergy += (doc['energy'] ?? 0.0).toDouble();
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(0.5),
            boxShadow: [
              BoxShadow(
                color:
                    const Color.fromARGB(255, 219, 217, 217).withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: SizedBox(
              // Use SizedBox to control Table width
              width: 330, // Set your desired width here
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
                        padding: EdgeInsets.all(6.0), // Increased padding
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
                        padding: EdgeInsets.all(6.0), // Increased padding
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
                        padding: EdgeInsets.all(6.0), // Reduced padding
                        child: Text(
                          'Date  (Today)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0), // Reduced padding
                        child: Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text('${_totalEnergy.toStringAsFixed(2)} kWh',
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            (totalEnergy <= 1
                                ? 'Low Energy Consumption'
                                : 'Energy Usage Moderate to High'),
                            style: TextStyle(fontSize: 11),
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoricalEnergyCard(Map<String, dynamic> data) {
    DateTime date = intl.DateFormat('yyyy-MM-dd-HH-mm-ss')
        .parse(data['date']); // Parse date and time
    double historicalTotalEnergy = (data['totalEnergy'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(0.5),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 219, 217, 217).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: SizedBox(
          width: 330, // Set your desired width here
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
                    padding: EdgeInsets.all(6.0), // Increased padding
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
                    padding: EdgeInsets.all(6.0), // Increased padding
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
                    padding: EdgeInsets.all(6.0), // Reduced padding
                    child: Text(
                      'Date',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0), // Reduced padding
                    child: Text(
                      DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
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
                    child: Text(
                        '$historicalTotalEnergy kWh', // Display historical data
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
                      padding: EdgeInsets.all(6.0),
                      child: Text(
                        (historicalTotalEnergy <= 1
                            ? 'Low Energy Consumption'
                            : 'Energy Usage Moderate to High'),
                        style: TextStyle(fontSize: 11),
                      )),
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
    return Column(
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
              Icon(
                Icons.bolt,
                color: Color.fromARGB(255, 231, 175, 22),
              ),
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
        ),
        const SizedBox(height: 50),
        TimeButtons(
          pageController: widget.pageController,
          selectedTabIndex: widget.selectedTabIndex,
          setSelectedTabIndex: widget.setSelectedTabIndex,
          onTimeButtonTapped: widget.onTimeButtonTapped,
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView(
            children: [
              _buildCurrentEnergyCard(),
              ..._historicalData
                  .map((data) => _buildHistoricalEnergyCard(data)),
            ],
          ),
        ),
        ElevatedButton(
          // Test button (starts the periodic timer)
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              _scheduleDataStorage(user.uid);
            }
          },
          child: const Text('Test'),
        ),
        ElevatedButton(
          // Stop button (stops the timer)
          onPressed: _resetHistoricalData,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Stop'),
        ),
        ElevatedButton(
          // "Clear" button (clears test data)
          onPressed: _clearTestDataFromFirestore, // Call the clear function
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange), // Style as needed
          child: const Text('Clear Test Data'),
        ),
      ],
    );
  }
}
