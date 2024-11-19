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
  double _totalEnergy = 0.0;
  bool _isLoading = true;
  late StreamSubscription<DatabaseEvent> _energySubscription;

  List<Map<String, dynamic>> _historicalData = []; // Store historical data

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

            // Schedule data storage for after 11:59 PM
            _scheduleDataStorage(user.uid, totalEnergy);
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

  void _scheduleDataStorage(String userId, double totalEnergy) {
    DateTime now = DateTime.now();
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);

    Duration timeUntilMidnight = nextMidnight.difference(now);

    Timer(timeUntilMidnight, () async {
      final historicalData = <String, dynamic>{
        'timestamp': DateTime.now(),
        'totalEnergy': totalEnergy,
      };

      try {
        String dateString =
            intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
        // Store the data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('historical_data')
            .doc(dateString)
            .collection('all_appliances')
            .doc('data')
            .set(historicalData, SetOptions(merge: true));

        print('Data stored successfully!');
      } catch (e) {
        print('Error storing data: $e');
      }
    });
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
                  // Get the date from the document ID
                  String date = doc.id;

                  // Get a reference to the all_appliances subcollection for this date
                  CollectionReference allAppliancesRef = FirebaseFirestore
                      .instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('historical_data')
                      .doc(date)
                      .collection('all_appliances');

                  // Fetch the 'data' document from the subcollection asynchronously
                  return allAppliancesRef
                      .doc('data')
                      .get()
                      .then((subcollectionDoc) {
                    // Return a map containing the date and totalEnergy
                    if (subcollectionDoc.exists) {
                      Map<String, dynamic> subcollectionData =
                          subcollectionDoc.data() as Map<String, dynamic>;
                      subcollectionData['date'] = date;
                      return subcollectionData;
                    }
                    return null; // Or handle the case where the 'data' document doesn't exist
                  });
                })
                .whereType<Map<String, dynamic>>()
                .toList(); //Remove any null values
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
    DateTime date = intl.DateFormat('yyyy-MM-dd').parse(data['date']);
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
                      'Date  (Today)',
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
          pageController: widget.pageController, // Access via widget.
          selectedTabIndex: widget.selectedTabIndex, // Access via widget.
          setSelectedTabIndex: widget.setSelectedTabIndex, // Access via widget.
          onTimeButtonTapped: widget.onTimeButtonTapped, // Access via widget.
        ),
        const SizedBox(height: 30),
        Expanded(
          child: _buildCurrentEnergyCard(),
        ),
      ],
    );
  }
}
