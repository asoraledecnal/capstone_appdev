import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: wide ? 520 : 460),
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 32,
                wide ? 48 : 40,
                wide ? 40 : 32,
                wide ? 40 : 32,
              ),
              decoration: BoxDecoration(
                color: AppColors.panelDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo (zoomed in, cropped to remove empty margins in the source art)
                  SizedBox(
                    height: wide ? 300 : 270,
                    child: ClipRect(
                      child: Transform.scale(
                        scale: 1.35,
                        child: Image.asset(
                          'assets/images/dict_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Divider
                  Center(
                    child: Container(
                      width: 120,
                      height: 1,
                      color: AppColors.sidebarBorder,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome back
                  const Text(
                    'WELCOME BACK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Username
                  const Text('USERNAME',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _userCtrl,
                    hint: 'Enter username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  const Text('PASSWORD',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _passCtrl,
                    hint: 'Enter password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button, right-aligned like the wireframe
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 170,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const HomeShell()),
                          );
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
        ),
      ),
    );
  }
}
