import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/widgets/time_buttons.dart'; // Import TimeButtons
import 'package:Emon/screens/dashboard_screen.dart'; // Import for PageController access

class DailyPage extends StatelessWidget {
  final int selectedTabIndex;
  final PageController pageController;
  final Function(int) setSelectedTabIndex;
  final Function(int) onTimeButtonTapped; // Add this callback

  const DailyPage(
      {Key? key,
      required this.selectedTabIndex,
      required this.pageController,
      required this.setSelectedTabIndex,
      required this.onTimeButtonTapped // Add this callback
      })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      // Use a Column to arrange TimeButtons and list
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
              Text("Daily Consumption",
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
          onTimeButtonTapped: (index) {
            // onTimeButtonTapped callback
            setSelectedTabIndex(index);
            pageController.jumpToPage(index);
          },
        ),
        Expanded(
          // Make the ListView expandable
          child: _buildDailyEnergyList(),
        ),
      ],
    );
  }

  Widget _buildDailyEnergyList() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("User not logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('dailyEnergy') // Your daily energy collection
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
            return const Center(child: Text('No daily energy data available.'));
          }

          return ListView.builder(
              // Or ListView if you don't need the itemCount
              shrinkWrap:
                  true, // Important to prevent unbounded height errors within a Column
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final timestamp = doc['timestamp'] as Timestamp;
                final energy = (doc['energy'] ?? 0)
                    .toDouble(); // Handle null energy values

                return Container(
                  // Inner containers with styling as needed
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
                        DateFormat('MMMM d, y').format(timestamp.toDate()),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 54, 83, 56), // Dark green
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(energy.toStringAsFixed(2) + ' kWh'),
                    ],
                  ),
                );
              });
        });
  }
}
