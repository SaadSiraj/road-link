import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Blue Accents
  static const Color primaryBlue = Color(
    0xFF1A56DB,
  ); // Vibrant blue for buttons and logo
  static const Color primaryBlueDark = Color(
    0xFF204DC4,
  ); // Darker blue for pressed states
  static const Color primaryBlueLight = Color(
    0xFF4DA3FF,
  ); // Lighter blue for hover states

  // Background Colors - Dark Theme
  static const Color background = Color(
    0xFF222B3C,
  ); // Dark blue-gray background
  static const Color scaffoldBackground = Color(
    0xFF111A2D,
  ); // Main scaffold background
  static const Color cardBackground = Color(
    0xFF222B3C,
  ); // Card/card-like section background
  static const Color backgroundSoft = Color(
    0xFF16202F,
  ); // Softer background variant

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Primary white text
  static const Color textSecondary = Color(0xFFA1A3A6); // Secondary gray text
  static const Color textTertiary = Color(0xFF6A6A6A); // Tertiary muted text

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF6A6A6A);
  static const Color lightGray = Color(0xFFB8B8B8);

  // Border & Divider Colors
  static const Color border = Color(0xFF2A3441); // Dark border for dark theme
  static const Color divider = Color(0xFF253040); // Divider color

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = primaryBlue;

  // Interactive Elements
  static const Color primary = primaryBlue;
  static const Color linkColor = primaryBlue; // Link color (same as primary)
  static const Color iconColor = Color(0xFFFFFFFF); // Icon color (white)
  static const Color inputBorder = Color(0xFF2A3441); // Input field border
  static const Color textFieldFillColor = Color(
    0xFF343C4D,
  ); // Text field fill color

  // Progress Indicator
  static const Color progressActive = primaryBlue;
  static const Color progressInactive = Color(0xFF2A3441);

  // Gradients
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  // Metrics Cards Gradient
  static const LinearGradient metricsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B5E20), // Dark green
      Color(0xFF2E7D32), // Medium green
    ],
  );
}
