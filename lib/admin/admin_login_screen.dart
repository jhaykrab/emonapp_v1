import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/SplashScreen.dart';
import 'package:Emon/admin/admin_page_screen.dart';
import 'package:Emon/screens/recovery_screen.dart';
import 'package:Emon/screens/dashboard_screen.dart';

class LoginScreenAdmin extends StatefulWidget {
  static const String routeName = '/login-admin';
  const LoginScreenAdmin({super.key});

  @override
  State<LoginScreenAdmin> createState() => _LoginScreenAdminState();
}

class _LoginScreenAdminState extends State<LoginScreenAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Hardcoded admin credentials (NOT RECOMMENDED FOR PRODUCTION)
  final String adminEmail = 'bc.jake.casundo@cvsu.edu.ph';
  final String adminPassword = 'J@kecasundo15';

  bool _obscureText = true; // To control password visibility

  // Add focus nodes for the text fields
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Function to handle admin login
  Future<void> adminLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Get entered email and password
        String email = _emailController.text.trim();
        String password = _passwordController.text.trim();

        // Compare with hardcoded admin credentials
        if (email == adminEmail && password == adminPassword) {
          // Admin login successful - Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color.fromARGB(255, 193, 223, 194),
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Admin login successful!',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 54, 83, 56),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                top: 0.0,
              ),
            ),
          );

          // Navigate to the admin page after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacementNamed(context, AdminPage.routeName);
        } else {
          // Show error using SnackBar with 'x' icon
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color.fromARGB(255, 238, 168, 168),
              content: Row(
                children: [
                  Icon(Icons.close_rounded,
                      color: Color.fromARGB(255, 63, 19, 16)),
                  SizedBox(width: 8),
                  Text(
                    'Invalid admin credentials.',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 63, 19, 16),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                top: 0.0,
              ),
            ),
          );
        }
      } catch (e) {
        // Handle other errors
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 238, 168, 168),
            content: Row(
              children: [
                Icon(Icons.close_rounded,
                    color: Color.fromARGB(255, 63, 19, 16)),
                SizedBox(width: 8),
                Text(
                  'Failed to login. Please try again.',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 63, 19, 16),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              top: 0.0,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Add the back button to the AppBar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 72, 100, 68),
          onPressed: () {
            // Navigate to SplashScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SplashScreen()),
            );
          },
        ),
        backgroundColor: const Color(0xFFf5f5f5),
        elevation: 0, // Remove AppBar shadow
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf5f5f5), Color(0xFFe8f5e9)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            // Remove extra padding from SingleChildScrollView
            padding: const EdgeInsets.only(bottom: 8.0), // Adjust as needed
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Let's sign you in!" Text
                  const Text(
                    "Let's sign you in!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Image.asset(
                    'assets/staticimgs/login-concept-illustration.png',
                    height: 200.0,
                    width: 200.0,
                  ),
                  const SizedBox(height: 8),

                  // Email Input Field with Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        cursorColor: const Color.fromARGB(
                            255, 54, 83, 56), // Set cursor color to green
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            // Change label color based on focus
                            color: _emailFocusNode.hasFocus
                                ? const Color.fromARGB(255, 54, 83, 56)
                                : const Color.fromARGB(255, 6, 17, 8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.green.shade800),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 54, 83, 56),
                              width: 2.0,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color.fromARGB(255, 54, 83, 56),
                            size: 20, // Adjusted icon size
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        // Validator for email
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$")
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null; // Return null if input is valid
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Password Input Field with Icon and Show/Hide
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        cursorColor: const Color.fromARGB(
                            255, 54, 83, 56), // Set cursor color to green
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            // Change label color based on focus
                            color: _passwordFocusNode.hasFocus
                                ? const Color.fromARGB(255, 54, 83, 56)
                                : const Color.fromARGB(
                                    255, 6, 17, 8), // Smaller label text
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 54, 83, 56),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 54, 83, 56),
                              width: 2.0,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color.fromARGB(255, 54, 83, 56),
                            size: 20, // Adjusted icon size
                          ),
                          suffixIcon: IconButton(
                            // Show/hide password button
                            icon: Icon(_obscureText
                                ? Icons.visibility
                                : Icons.visibility_off),
                            color: const Color.fromARGB(255, 54, 83, 56),
                            iconSize: 20, // Adjusted icon size
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        obscureText:
                            _obscureText, // Initially hide the Access Key
                        // Validator for password
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null; // Return null if input is valid
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // "Forgot Password?" Row (You can remove this if not needed for admin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Forgot Password? ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 72, 100, 68),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // Navigate to RecoveryScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RecoveryScreen()),
                          );
                        },
                        child: const Text(
                          "Reset Here!",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 72, 100, 68),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sign In Button
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        adminLogin();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                      padding: const EdgeInsets.symmetric(
                          vertical: 17, horizontal: 115),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFFe8f5e9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
