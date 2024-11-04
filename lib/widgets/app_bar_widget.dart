import 'package:flutter/material.dart';
import 'package:Emon/screens/SplashScreen.dart'; // Import your DashboardScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Emon/screens/dashboard_screen.dart ';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String userName;

  const AppBarWidget({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(60.0),
      child: AppBar(
        backgroundColor: const Color.fromARGB(255, 72, 100, 68),
        elevation: 3,
        shadowColor: Colors.grey[200],
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/ic_launcher.png'),
              radius: 20,
            ),
            SizedBox(width: 10),
            Text(
              userName,
              style: TextStyle(
                color: Color(0xFFe8f5e9),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Spacer(),
            // Logout Button
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFe8f5e9)),
              onPressed: () => _signOut(context), // Pass context here
            ),
            IconButton(
              icon: Icon(Icons.settings),
              color: Color(0xFFe8f5e9),
              onPressed: () {
                print("Settings button pressed");
                // Add your settings button functionality here
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(60.0);

  // Function to sign out the admin (now accepts context)
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Sign out using FirebaseAuth
    // Navigate to SplashScreen after sign-out
    Navigator.pushReplacementNamed(context, SplashScreen.routeName);
  }
}
