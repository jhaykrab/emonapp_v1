import 'package:flutter/material.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String userName;

  const AppBarWidget({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
          IconButton(
            icon: Icon(Icons.help_outline),
            color: Color(0xFFe8f5e9),
            onPressed: () {
              print("Help button pressed");
              // Add your help button functionality here
            },
          )
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
