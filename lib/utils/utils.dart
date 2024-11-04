// utils.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Emon/screens/SplashScreen.dart'; // Import your SplashScreen

// Global sign-out function
Future<void> signOut(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushReplacementNamed(context, SplashScreen.routeName);
}
