import 'package:flutter/material.dart';
import 'package:Emon/screens/setup_appliance_screen.dart';
import 'package:Emon/screens/SplashScreenLogo.dart';
import 'package:Emon/screens/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Emon/screens/dashboard_screen.dart';
import 'package:Emon/screens/login_screen.dart';
import 'package:Emon/admin/admin_page_screen.dart';
import 'package:Emon/admin/admin_login_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:Emon/services/global_state.dart';
import 'package:Emon/providers/appliance_provider.dart';
import 'package:Emon/screens/appliance_list.dart';
import 'package:intl/intl.dart' as intl;
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
      initialRoute: SplashScreenLogo.routeName,
      routes: {
        SplashScreenLogo.routeName: (context) => const SplashScreenLogo(),
        SplashScreen.routeName: (context) => const SplashScreen(),
        SetupApplianceScreen.routeName: (context) =>
            const SetupApplianceScreen(),
        ApplianceListScreen.routeName: (context) =>
            const ApplianceListScreen(), // Added route for ApplianceListScreen
        '/login-screen': (context) =>
            const LoginScreen(), // Keep this if you use it elsewhere
        LoginScreenAdmin.routeName: (context) => const LoginScreenAdmin(),
        AdminPage.routeName: (context) => const AdminPage(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
      },
    );
  }
}
