import 'package:Emon/screens/login_screen.dart';
import 'package:Emon/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:Emon/admin/admin_login_screen.dart';

class SplashScreen extends StatelessWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf5f5f5), Color(0xFFe8f5e9)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_light.png',
                height: 280.0,
                width: 280.0,
              ),
              const SizedBox(height: 10),

              // Sign In as Admin Button with Shadow
              _buildElevatedButton(
                'Signin as Admin',
                () {
                  // TODO: Navigate to Admin Login Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreenAdmin()),
                  );
                },
                buttonColor:
                    Color.fromARGB(255, 72, 100, 68), // Dark green color
              ),
              const SizedBox(height: 25),

              // Sign In Button with Shadow
              _buildElevatedButton(
                'Signin as User',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                buttonColor:
                    Color.fromARGB(255, 72, 100, 68), // Dark green color
              ),
              const SizedBox(height: 25),

              // Sign Up Button with Shadow
              _buildElevatedButton(
                'Sign Up',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                  );
                },
                isOutlined: true, // Make this button outlined
                buttonColor: Colors.white, // Set button color to white
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build elevated buttons with consistent styling
  Widget _buildElevatedButton(String label, VoidCallback onPressed,
      {bool isOutlined = false, Color buttonColor = Colors.transparent}) {
    return Container(
      width: 275, // Set a fixed width for all buttons
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor, // Use the provided button color
          padding: const EdgeInsets.symmetric(vertical: 17),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 1.0, // Add letter spacing here
          ),
          foregroundColor: isOutlined
              ? const Color.fromARGB(255, 54, 83, 56)
              : const Color(0xFFe8f5e9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: isOutlined
                ? const BorderSide(
                    color: Color.fromARGB(255, 54, 83, 56), width: 1.0)
                : BorderSide.none, // Add border only for outlined button
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
