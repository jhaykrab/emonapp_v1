import 'package:Emon/screens/code_verification_screen.dart'; // Correct import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Emon/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

// Recovery Screen (First Screen)
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final emailController = TextEditingController();

  // Function to handle password reset
  Future<void> resetPassword() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text.trim();

      try {
        // Send password reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        // Display success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Password reset email sent successfully!',
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

        // Navigate to LoginScreen after success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Authentication errors
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.close, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'No user found for that email.',
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
        } else {
          // Handle other errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.close, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Failed to send password reset email. Please try again.',
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
                  'Failed to send password reset email. Please try again.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 72, 100, 68),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Account Recovery",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/staticimgs/stock-exchange-data-concept.png',
                    height: 275.0,
                    width: 275.0,
                  ),
                  const SizedBox(height: 1),

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

                  const SizedBox(height: 17),
                  // Recover Button with Shadow
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Call the resetPassword function
                          resetPassword();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                        padding: const EdgeInsets.symmetric(
                            vertical: 17, horizontal: 95),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          letterSpacing: 2.0,
                        ),
                        foregroundColor: const Color(0xFFe8f5e9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: const Text('Reset Password'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
