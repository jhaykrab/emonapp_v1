import 'dart:async';
import 'package:Emon/screens/SplashScreen.dart';
import 'package:drop_shadow_image/drop_shadow_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/material.dart';

class SplashScreenLogo extends StatefulWidget {
  static const String routeName = '/splash-logo';
  const SplashScreenLogo({super.key});

  @override
  State<SplashScreenLogo> createState() => _SplashScreenLogoState();
}

class _SplashScreenLogoState extends State<SplashScreenLogo> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const SplashScreen()), // Navigate to SplashScreen
      );
    });
  }

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
          child: AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 800),
            child: FadeInAnimation(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Drop Shadow
                  DropShadowImage(
                    offset: const Offset(4, 4),
                    scale: 1,
                    blurRadius: 15,
                    image: Image.asset(
                      'assets/images/logo_single.png',
                      height: 225.0,
                      width: 225.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // "EMON" Text (without animation)
                  const Text(
                    'EMON',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color.fromARGB(255, 54, 83, 56),
                      fontFamily: 'Kanit',
                      letterSpacing: 8.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  const Text(
                    'Save Energy at your Convenience',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 54, 83, 56),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Loading Indicator
                  const SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 54, 83, 56),
                      ),
                      backgroundColor: Colors.transparent,
                      strokeWidth: 2.5,
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
