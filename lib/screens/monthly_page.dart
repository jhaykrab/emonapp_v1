import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/time_buttons.dart'; // Import TimeButtons
import 'dashboard_screen.dart'; // Import for callback and PageController

class MonthlyPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
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
              Text("Monthly Consumption",
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
          // Make ListView take the remaining space
          child: _buildMonthlyEnergyList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyEnergyList() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('monthlyEnergy') // Your monthly energy collection
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No monthly energy data available.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final timestamp = doc['timestamp'] as Timestamp;
            final energy = (doc['energy'] ?? 0).toDouble();

            // Format the date to show the month and year
            final formattedDate =
                DateFormat('MMMM y').format(timestamp.toDate());

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
                  Text(
                    formattedDate, // Display the formatted date
                    style: const TextStyle(
                      color: Color.fromARGB(255, 54, 83, 56),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
