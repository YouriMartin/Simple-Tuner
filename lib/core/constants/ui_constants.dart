import 'package:flutter/material.dart';

/// UI-related constants
class UIConstants {
  // Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF424242);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);

  // LED Colors
  static const Color ledInTune = Colors.green;
  static const Color ledSlightlyOff = Colors.orange;
  static const Color ledVeryOff = Colors.red;
  static const Color ledInactive = Color(0xFF333333);

  // Dimensions
  static const double ledRadius = 8.0;
  static const double ledSpacing = 4.0;
  static const double tunerRadius = 120.0;

  // Animation
  static const Duration ledAnimationDuration = Duration(milliseconds: 100);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
}
