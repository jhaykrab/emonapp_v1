import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/time_buttons.dart'; // Import TimeButtons
import 'dashboard_screen.dart'; // Import for the callback and page controller

class WeeklyPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      // Column to hold TimeButtons and the list
      children: [
        const SizedBox(height: 25),
        Container(
          // Use a Container instead of OutlinedButton
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(255, 54, 83, 56), // Dark green border
              width: 2.0, // Increased border width
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.bolt,
                  color: Color.fromARGB(255, 231, 175, 22)), // Icon with color
              SizedBox(width: 8),
              Text("Weekly Consumption",
                  style: TextStyle(
                     fontWeight: FontWeight.bold,
                      color:
                          Color.fromARGB(255, 54, 83, 56))), // Text with color
            ],
          ),
        ),
        SizedBox(height: 50),
        TimeButtons(
          pageController: pageController,
          selectedTabIndex: selectedTabIndex,
          setSelectedTabIndex: setSelectedTabIndex,
          onTimeButtonTapped: onTimeButtonTapped,
        ),
        Expanded(
          // Expand the ListView to fill available space
          child: _buildWeeklyEnergyList(),
        ),
      ],
    );
  }

  Widget _buildWeeklyEnergyList() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weeklyEnergy') // Your weekly energy collection
          .orderBy('timestamp', descending: true) // Order by timestamp
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No weekly energy data available.'));
        }

        return ListView.builder(
          shrinkWrap: true, // Important: prevent unbounded height errors
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final timestamp = doc['timestamp'] as Timestamp;
            final energy = (doc['energy'] ?? 0).toDouble();

            // Format the date to show the start and end of the week
            final weekStart = timestamp
                .toDate()
                .subtract(Duration(days: timestamp.toDate().weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            final formattedDate =
                '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedDate, // Display the formatted date range
                      style: const TextStyle(
                        color: Color.fromARGB(255, 54, 83, 56),
                        fontWeight: FontWeight.bold,
                      )),
                  Text(energy.toStringAsFixed(2) + ' kWh'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
