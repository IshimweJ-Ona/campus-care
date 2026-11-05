
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF173B8F);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Splash screen
  static const Color splashBackground = Color(0xFF07111F);
  static const Color splashSurface = Color(0xFF101F35);
  static const Color glow = Color(0xFF3B82F6);

  // General app surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Button colors
  static const Color buttonPrimary = primary;
  static const Color buttonPrimaryPressed = primaryDark;
  static const Color buttonSecondary = Color(0xFFEFF6FF);
  static const Color buttonSecondaryText = primaryDark;
  static const Color buttonOutlined = Colors.transparent;
  static const Color buttonOutlinedBorder = primary;
  static const Color buttonText = primary;
  static const Color buttonDisabled = Color(0xFFE4E7EC);
  static const Color buttonDisabledText = Color(0xFF98A2B3);
  static const Color buttonDestructive = Color(0xFFDC2626);
  static const Color buttonDestructivePressed = Color(0xFFB91C1C);
  static const Color buttonOnDestructive = Color(0xFFFFFFFF);

  // Form fields and borders
  static const Color border = Color(0xFFD0D5DD);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputFocusedBorder = primary;

  // Status colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
}
