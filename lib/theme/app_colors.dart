import 'package:flutter/material.dart';

/// Centralized color palette pulled from the Wazuh SIEM dashboard mockups.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0F14);
  static const Color panelDark = Color(0xFF0E1319);
  static const Color card = Color(0xFF161C24);
  static const Color cardBorder = Color(0xFF232B36);
  static const Color sidebarBorder = Color(0xFF1E2530);

  static const Color textPrimary = Color(0xFFF3F5F7);
  static const Color textSecondary = Color(0xFF8A94A3);
  static const Color textMuted = Color(0xFF5C6675);

  static const Color teal = Color(0xFF14C8A6);
  static const Color tealDark = Color(0xFF0F9D82);

  static const Color red = Color(0xFFE84C4C);
  static const Color orange = Color(0xFFE8A23C);
  static const Color blue = Color(0xFF3D8BFF);
  static const Color green = Color(0xFF2ECC8F);

  static Color severityColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
      case 'high':
        return level.toLowerCase() == 'critical' ? red : orange;
      case 'medium':
        return orange;
      case 'low':
        return blue;
      default:
        return green;
    }
  }
}
