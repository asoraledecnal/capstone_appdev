import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WazuhApp());
}

class WazuhApp extends StatelessWidget {
  const WazuhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DICT-4A Wazuh SIEM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.dark,
          surface: AppColors.background,
        ),
      ),
      // Shows a branded intro (logo + app name + loading indicator) for a
      // beat before handing off to the login screen, instead of jumping
      // straight from the native splash into the login form.
      home: const SplashScreen(),
    );
  }
}
