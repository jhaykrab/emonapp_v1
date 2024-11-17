import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Emon/screens/dashboard_screen.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:Emon/screens/signup_screen.dart';
import 'package:Emon/screens/recovery_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/SplashScreen.dart';
import 'package:Emon/services/database.dart';
import 'package:Emon/models/user_data.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _firstName = "User";
  String email = ""; // Initialize
  String password = ""; // Initialize
  bool _isLoginButtonEnabled = true;
  int _loginAttempts = 0;
  Timer? _timer;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose(); // Dispose controllers
    passwordController.dispose(); // Dispose controllers
    _emailFocusNode.dispose(); // Dispose focus nodes
    _passwordFocusNode.dispose(); // Dispose focus nodes
    super.dispose();
  }

  void _startLoginCooldown() {
    setState(() {
      _isLoginButtonEnabled = false;
      _loginAttempts++;
    });

    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        // Ensure widget is still mounted before calling setState
        setState(() {
          _isLoginButtonEnabled = true;
          _loginAttempts = 0;
        });
      }
    });
  }

  // Function to handle user login
  Future<void> userLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Sign in with email and password
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Fetch the user's UID
        String uid = userCredential.user!.uid;

        // Fetch the user's first name from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await _firestore.collection('users').doc(uid).get();

        // Check if the document exists and fetch the first name
        if (userDoc.exists) {
          // Access the 'user_data' field and then 'firstName'
          _firstName = userDoc.get('user_data')['firstName'] ?? "User";
        }

        // Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: const Color.fromARGB(
                        255, 54, 83, 56)), // Rounded check icon
                const SizedBox(width: 8),
                RichText(
                  // RichText for styled text
                  text: TextSpan(
                    text: 'Welcome back ',
                    style: const TextStyle(
                        color: const Color.fromARGB(
                            255, 54, 83, 56), // Darker green
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: ' $_firstName!',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: const Color.fromARGB(
                                255, 54, 83, 56)), // Darker green
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor:
                const Color.fromARGB(255, 211, 243, 213), // Darker green
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            margin:
                const EdgeInsets.only(bottom: 20.0, left: 15.0, right: 15.0),
          ),
        );
        // Navigate to DashboardScreen after a short delay
        await Future.delayed(
            const Duration(milliseconds: 500)); // Adjust delay as needed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ApplianceListScreen()),
        );
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Authentication errors
        String errorMessage = 'An error occurred.'; // Generic error message

        if (mounted) {
          // Ensure widget is still mounted
          setState(() {
            switch (e.code) {
              case 'invalid-email':
                errorMessage = 'The email you provided is invalid.';
                break;
              case 'user-not-found':
                errorMessage = 'No user found for that email.';
                break;
              case 'wrong-password':
                errorMessage = 'Wrong password provided.';
                break;
              case 'user-disabled':
                errorMessage = 'This user has been disabled.';
                break;
              case 'too-many-requests':
                errorMessage = 'Too many requests. Try again later.';
                break;
              default: // Handle any other FirebaseAuthException
                errorMessage = 'Login failed. Check your credentials.';
                break;
            }

            // Show error SnackBar inside setState
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color.fromARGB(255, 110, 36, 36)),
                    const SizedBox(width: 8),
                    Text(errorMessage,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 110, 36, 36))),
                  ],
                ),
                backgroundColor:
                    const Color.fromARGB(255, 243, 208, 206), // Lighter red
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                margin: const EdgeInsets.only(
                    bottom: 20.0, left: 15.0, right: 15.0),
              ),
            );
          });
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
                  'Failed to login. Please check your credentials.',
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
                        controller: emailController,
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
                        controller: passwordController,
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

                  // "Already have an account? Sign In"
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
                          // Navigate to LoginScreen
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
                        userLogin();
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
                  // Sign Up Button with Shadow
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 17, horizontal: 76),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Valera_Round',
                        ),
                        foregroundColor: const Color.fromARGB(255, 54, 83, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          side: const BorderSide(
                              color: Color.fromARGB(255, 54, 83, 56),
                              width: 1.0), // Add border
                        ),
                      ),
                      child: const Text('Create an Account'),
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

  Future<void> _login() async {
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ApplianceListScreen()),
    );
  }
}
