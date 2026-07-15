import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: Generated via 'flutterfire configure' command
import 'firebase_options.dart'; 
import 'theme/app_colors.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  // 1. Flutter Engine Binding (Kritikal para sa async initialization)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase Backend Initialization (Core Requirement para sa IT 332)
  // Ito ang magko-connect sa Firestore database mo na may 50 dummy records
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. TODO (For Capstone): Establish HTTP Overrides & SSL Certificate Pinning 
  // para sa Hub-and-Spoke VyOS WAN core.

  // 4. Wrap the app in ProviderScope para sa Riverpod state management
  runApp(const ProviderScope(child: SentinelApp()));
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Na-update ang title para sumalamin sa na-approve nating enterprise concept
      title: 'Sentinel IV-A', 
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
      home: const LoginScreen(),
    );
  }
}