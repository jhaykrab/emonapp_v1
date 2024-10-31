import 'package:flutter/material.dart';
import 'package:Emon/widgets/app_bar_widget.dart';
import 'package:Emon/widgets/bottom_nav_bar_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/models/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplianceListScreen extends StatefulWidget {
  const ApplianceListScreen({super.key});

  @override
  State<ApplianceListScreen> createState() => _ApplianceListScreenState();
}

class _ApplianceListScreenState extends State<ApplianceListScreen> {
  int _selectedIndex = 1;
  User? _user;
  String _userName = '';
  UserData? _userData;

  final DatabaseService _dbService = DatabaseService();

  // List to store appliance data fetched from Firestore
  List<Map<String, dynamic>> _appliances = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _fetchApplianceData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      UserData? userData = await _dbService.getUserData(_user!.uid);

      if (mounted) {
        setState(() {
          _userData = userData;
          _userName = userData != null
              ? '${userData.firstName ?? ''} ${userData.lastName ?? ''}'
              : 'User Full Name';
        });
      }
    }
  }

  // Function to fetch appliance data from Firestore
  Future<void> _fetchApplianceData() async {
    if (_user != null) {
      _appliances = await _dbService.getApplianceData(_user!.uid);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(userName: _userName),
      body: Container(
        color: const Color(0xFFE8F5E9),
        child: _appliances.isEmpty
            ? const Center(
                child: Text('No appliances set up yet.'),
              )
            : ListView.builder(
                itemCount: _appliances.length,
                itemBuilder: (context, index) {
                  final appliance = _appliances[index];
                  // Access the document ID directly inside the itemBuilder
                  final applianceDocId = appliance['docId'];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 223, 236, 219),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconData(appliance['icon'] ?? 0,
                                fontFamily: 'MaterialIcons'),
                            size: 40,
                            color: const Color.fromARGB(255, 72, 100, 68),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.wifi, // WiFi icon
                            size: 24,
                            color:
                                appliance['isOn'] ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                      title: Text(
                        appliance['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        '${appliance['deviceNumber']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Distribute widgets
                        children: [
                          // Constrained Runtime Text
                          SizedBox(
                            width: 80, // Adjust width as needed
                            child: Text(
                              '${appliance['runtimehr'] ?? 0}h ${appliance['runtimemin'] ?? 0}m ${appliance['runtimesec'] ?? 0}s',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),

                          // Toggle Switch (Firestore version)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(_user!.uid)
                                .collection('registered_appliances')
                                .doc(applianceDocId) // Use the document ID here
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                bool isOn = snapshot.data!['isOn'] ?? false;
                                return Switch(
                                  value: isOn,
                                  onChanged: (value) async {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_user!.uid)
                                          .collection('registered_appliances')
                                          .doc(applianceDocId)
                                          .update({'isOn': value});
                                    } catch (e) {
                                      print(
                                          'Error updating appliance state: $e');
                                      // Handle the error, e.g., show a snackbar
                                    }
                                  },
                                  activeTrackColor: Colors.green[700],
                                  activeColor: Colors.green[900],
                                  inactiveTrackColor: Colors.grey[400],
                                  inactiveThumbColor: Colors.grey[300],
                                );
                              } else {
                                return const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 72, 100, 68),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
