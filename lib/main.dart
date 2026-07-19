import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // While Firebase is checking the token, show a blank loading screen
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
            );
          }
          // If the user is successfully logged in, take them to the dashboard
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeShell();
          }
          // Otherwise, send them to the login screen
          return const LoginScreen();
        },
      ),
    );
  }
}
