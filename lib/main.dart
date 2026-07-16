import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/login_screen.dart';

void main() {
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
      home: const LoginScreen(),
    );
  }
}
