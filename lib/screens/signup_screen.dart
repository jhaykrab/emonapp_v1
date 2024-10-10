import 'package:Emon/screens/login_screen.dart'; // Adjust import if needed
import 'package:Emon/screens/register_devices_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  static const String routeName = '/signup';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Function to handle user registration
  Future<void> registration() async {
    if (_formKey.currentState!.validate()) {
      // Get the email and password from the controllers
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      String firstname = firstnameController.text.trim();
      String lastname = lastnameController.text.trim();

      try {
        // Create user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Display success message with check icon
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'User account created successfully!',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 54, 83, 56),
                  ),
                ),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 193, 223, 194),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              top: 0.0,
              left: 8.0,
              right: 8.0,
            ),
          ),
        );

        // Add a delay before navigating
        await Future.delayed(
            const Duration(milliseconds: 1000)); // Adjust delay as needed

        // Navigate to DeviceScreen
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DevicesScreen()));
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Authentication errors
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.close, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'The password provided is too weak.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 63, 19, 16),
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: Color.fromARGB(255, 238, 168, 168),
            ),
          );
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.close, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'The account already exists for that email.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 63, 19, 16),
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: Color.fromARGB(255, 238, 168, 168),
            ),
          );
        }
      } catch (e) {
        // Handle other errors
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.close, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Failed to create an account. Please try again.',
                  style: TextStyle(
                    color: Color.fromARGB(255, 63, 19, 16),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 238, 168, 168),
          ),
        );
      }
    }
  }

  bool _obscureText = true; // To control password visibility

  // Add focus nodes for the text fields
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Controllers for the text fields
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Let's Get Started!" Text
                  const Text(
                    "Let's Get Started!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Logo - You might want to use a different image here
                  Image.asset(
                    'assets/staticimgs/mobile-login-concept-illustration.png',
                    height: 200.0,
                    width: 200.0,
                  ),
                  const SizedBox(height: 16),

                  // Email Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        focusNode: _emailFocusNode,
                        controller: emailController,
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            fontSize: 13,
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
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$")
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // First Name Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        focusNode: _firstNameFocusNode,
                        controller: firstnameController,
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: _firstNameFocusNode.hasFocus
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
                            Icons.person,
                            color: Color.fromARGB(255, 54, 83, 56),
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Last Name Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        focusNode: _lastNameFocusNode,
                        controller: lastnameController,
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: _lastNameFocusNode.hasFocus
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
                            Icons.person,
                            color: Color.fromARGB(255, 54, 83, 56),
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  // Set Password Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        focusNode: _passwordFocusNode,
                        controller: passwordController,
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'Set Password',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: _passwordFocusNode.hasFocus
                                ? const Color.fromARGB(255, 54, 83, 56)
                                : const Color.fromARGB(255, 6, 17, 8),
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
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText
                                ? Icons.visibility
                                : Icons.visibility_off),
                            color: const Color.fromARGB(255, 54, 83, 56),
                            iconSize: 20,
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureText,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (!RegExp(
                                  r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$')
                              .hasMatch(value)) {
                            return 'Password must have at least:\n- one uppercase, one lowercase, \n- one number, and one special character. \n- Minimum 8 characters. \n (e.g: J@kecasundo15)'; // Return a String error message
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: () {
                      // Call the registration function when the button is pressed
                      registration();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                      padding: const EdgeInsets.symmetric(
                          vertical: 17, horizontal: 113),
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
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFFe8f5e9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // "Already have an account? Sign In"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
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
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 72, 100, 68),
                          ),
                        ),
                      ),
                    ],
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
