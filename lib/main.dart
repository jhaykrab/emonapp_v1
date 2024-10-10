import 'package:flutter/material.dart';
import 'package:Emon/screens/register_devices_screen.dart';
import 'package:Emon/screens/SplashScreenLogo.dart';
import 'package:Emon/screens/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Import your firebase_options.dart file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the correct options
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emon',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Set SplashScreenLogo as the initial route
      initialRoute: SplashScreenLogo.routeName,
      routes: {
        SplashScreenLogo.routeName: (context) => const SplashScreenLogo(),
        SplashScreen.routeName: (context) => const SplashScreen(),
        DevicesScreen.routeName: (context) => const DevicesScreen(),
      },
    );
  }
}
