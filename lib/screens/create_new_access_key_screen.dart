import 'package:Emon/screens/login_screen.dart'; // Adjust import if needed
import 'package:flutter/material.dart';

class CreateNewAccessKeyScreen extends StatefulWidget {
  const CreateNewAccessKeyScreen({super.key});

  @override
  State<CreateNewAccessKeyScreen> createState() =>
      _CreateNewAccessKeyScreenState();
}

class _CreateNewAccessKeyScreenState extends State<CreateNewAccessKeyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true; // To control new access key visibility
  String _newAccessKey = ''; // Store the newly created access key

  // Add focus node for the new access key text field
  final FocusNode _newAccessKeyFocusNode = FocusNode();

  final TextEditingController _accessKeyController = TextEditingController();

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
                    "Create New Access Key",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 72, 100, 68),
                      fontFamily: 'Rubik',
                    ),
                  ),
                  const SizedBox(height: 10),

                  Image.asset(
                    'assets/staticimgs/tech-support-concept-illustration.png', // Replace with appropriate image
                    height: 250.0,
                    width: 250.0,
                  ),
                  const SizedBox(height: 1),

                  // New Access Key Input Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 8),
                    child: SizedBox(
                      width: 275,
                      child: TextFormField(
                        controller:
                            _accessKeyController, // Add the controller here
                        focusNode: _newAccessKeyFocusNode,
                        cursorColor: const Color.fromARGB(255, 54, 83, 56),
                        decoration: InputDecoration(
                          labelText: 'New Access Key',
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: _newAccessKeyFocusNode.hasFocus
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
                            Icons.key,
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
                            return 'Please enter a new access key';
                          }
                          if (value.length < 8) {
                            return 'Access key must be at least 8 characters';
                          }
                          if (!RegExp(
                                  r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$')
                              .hasMatch(value)) {
                            return 'Access key must have at least:\n- one uppercase, one lowercase, \n- one number, and one special character. \n- Minimum 8 characters. \n (e.g: J@kecasundo15)'; // Return a String error message
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 17),
                  // Create Button with Shadow
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
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Get the access key entered by the user
                          _newAccessKey = _accessKeyController.text;

                          // ... (Your logic to send the _newAccessKey to the backend) ...

                          // Show Snackbar with the new access key
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully created a new access key: $_newAccessKey',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 54, 83, 56),
                                ),
                              ),
                              backgroundColor:
                                  const Color.fromARGB(255, 193, 223, 194),
                            ),
                          );

                          // Navigate to the login screen after a delay
                          Future.delayed(const Duration(seconds: 2), () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          });
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
                      child: const Text('Create'),
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

  // ... (You can remove the _generateNewAccessKey function since you're getting the key from user input) ...
}
