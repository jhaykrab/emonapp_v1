/* BACKUP CODE FOR CODE VERIFICATIONSCREEN

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Emon/screens/create_new_access_key_screen.dart'; // Make sure this import is correct

// Code Verification Screen (Second Screen)
class CodeVerificationScreen extends StatefulWidget {
  const CodeVerificationScreen({super.key});

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isResendEnabled = false; // Track if resend is enabled
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _isResendEnabled = true; // Enable resend after 60 seconds
          _timer?.cancel();
        }
      });
    });
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
                    "Code Verification",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/staticimgs/tech-support-concept-illustration.png',
                    height: 250.0,
                    width: 250.0,
                  ),
                  const SizedBox(height: 1),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'Enter Code',
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 6, 17, 8),
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
                            Icons.password,
                            color: Color.fromARGB(255, 54, 83, 56),
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the code';
                          }
                          if (value.length != 6) {
                            return 'Code must be 6 digits';
                          }
                          // You can add more specific validation for the code format
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 17),
                  // Confirm Button with Shadow
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
                          // Navigate to CreateNewAccessKeyScreen after successful validation
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CreateNewAccessKeyScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 54, 83, 56),
                        padding: const EdgeInsets.symmetric(
                            vertical: 17, horizontal: 108),
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
                      child: const Text('Confirm'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Resend Code Text
                  MouseRegion(
                    cursor: _isResendEnabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTap: _isResendEnabled
                          ? () {
                              // TODO: Implement resend code logic
                              print('Resend code tapped!');
                              setState(() {
                                _isResendEnabled = false;
                                _secondsRemaining = 60;
                                _startTimer();
                              });
                            }
                          : null,
                      child: Text(
                        _secondsRemaining > 0
                            ? 'Resend code after $_secondsRemaining s'
                            : 'Resend code',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isResendEnabled
                              ? const Color.fromARGB(255, 72, 100, 68)
                              : Colors.grey,
                        ),
                      ),
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

*/
