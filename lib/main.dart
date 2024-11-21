import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:Emon/screens/SplashScreenLogo.dart';
import 'package:Emon/screens/SplashScreen.dart';
import 'package:Emon/screens/dashboard_screen.dart';
import 'package:Emon/screens/login_screen.dart';
import 'package:Emon/admin/admin_page_screen.dart';
import 'package:Emon/admin/admin_login_screen.dart';
import 'package:Emon/providers/appliance_provider.dart';
import 'package:Emon/services/global_state.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GlobalState()),
        ChangeNotifierProvider(create: (context) => ApplianceProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreenLogo.routeName,
      routes: {
        SplashScreenLogo.routeName: (context) {
          debugPrint("Navigating to SplashScreenLogo");
          return const SplashScreenLogo();
        },
        SplashScreen.routeName: (context) {
          debugPrint("Navigating to SplashScreen");
          return const SplashScreen();
        },
        SetupApplianceScreen.routeName: (context) {
          debugPrint("Navigating to SetupApplianceScreen");
          return const SetupApplianceScreen();
        },
        ApplianceListScreen.routeName: (context) {
          debugPrint("Navigating to ApplianceListScreen");
          return const ApplianceListScreen();
        },
        LoginScreen.routeName: (context) {
          debugPrint("Navigating to LoginScreen");
          return const LoginScreen();
        },
        LoginScreenAdmin.routeName: (context) {
          debugPrint("Navigating to Admin Login Screen");
          return const LoginScreenAdmin();
        },
        AdminPage.routeName: (context) {
          debugPrint("Navigating to AdminPage");
          return const AdminPage();
        },
        DashboardScreen.routeName: (context) {
          debugPrint("Navigating to DashboardScreen");
          return const DashboardScreen();
        },
      },
    );
  }
}
