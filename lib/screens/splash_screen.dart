import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

/// Branded intro screen shown right after the app boots, before the
/// login screen. Unlike the native OS-level splash (which only supports a
/// bare image + background color, no layout control), this is a normal
/// Flutter widget — so the logo, title, subtitle, and loading indicator
/// can all be sized and spaced properly instead of the logo looking like
/// a small badge floating alone in a big dark screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    // Firebase.initializeApp() already finished in main() before this
    // widget is even built, so this delay is purely to let the branded
    // intro be visible for a moment rather than flashing by instantly.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const LoginScreen(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo sits inside a soft rounded panel with a subtle teal
              // glow instead of floating bare on the background — gives it
              // an anchored, intentional look rather than a small stamp in
              // empty space.
              Container(
                width: 168,
                height: 168,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panelDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.35),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/dict_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'DICT-4A WAZUH',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SIEM/EDR HUB-AND-SPOKE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(AppColors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
