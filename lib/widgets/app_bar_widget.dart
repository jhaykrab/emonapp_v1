import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String userName;

  const AppBarWidget({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(60.0), // Set the desired height here
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
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/LoginScreen');
              },
              child: Text(
                "Logout",
                style: TextStyle(
                  color: Color(0xFFe8f5e9),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
  Size get preferredSize => Size.fromHeight(60.0); // Also set the height here
}
