import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Icon-inspired palette
  static const Color primaryBackground = Color(0xFF0A0E21); // Deep dark blue
  static const Color surfaceBackground = Color(0xFF1A1F35); // Slightly lighter blue
  static const Color accentBlue = Color(0xFF4A90E2); // Icon blue
  
  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF6B9BD4); // Lighter blue
  static const Color tertiaryBlue = Color(0xFF8FB3E8); // Light blue
  static const Color accentCyan = Color(0xFF64B5F6); // Cyan accent
  
  // Text Colors
  static const Color primaryText = Color(0xFFE8F4FD); // Light blue-white
  static const Color headingText = Color(0xFFFFFFFF); // Pure white
  static const Color secondaryText = Color(0xFFB8C7D9); // Light blue-gray
  static const Color disabledText = Color(0xFF6B7A8C); // Muted blue-gray
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Red
  static const Color errorRed = Color(0xFFF44336); // Red for errors
  
  // Border Colors
  static const Color borderLight = Color(0xFF2A3F5F); // Blue-gray
  static const Color borderMedium = Color(0xFF1E2A3F); // Darker blue-gray
  static const Color borderDark = Color(0xFF0F1A2A); // Very dark blue
  
  // Overlay Colors
  static const Color overlayLight = Color(0x1AFFFFFF);
  static const Color overlayMedium = Color(0x33FFFFFF);
  static const Color overlayDark = Color(0x66FFFFFF);
  
  // Chat Colors
  static const Color userMessageBackground = Color(0xFF4A90E2); // Icon blue
  static const Color aiMessageBackground = Color(0xFF1A1F35); // Surface background
  static const Color userMessageText = Color(0xFFFFFFFF);
  static const Color aiMessageText = Color(0xFFE8F4FD);
  
  // Button Colors
  static const Color primaryButton = Color(0xFF4A90E2); // Icon blue
  static const Color secondaryButton = Color(0xFF1A1F35); // Surface background
  static const Color dangerButton = Color(0xFFF44336);
  
  // Input Colors
  static const Color inputBackground = Color(0xFF1A1F35); // Surface background
  static const Color inputBorder = Color(0xFF2A3F5F); // Border light
  static const Color inputFocusedBorder = Color(0xFF4A90E2); // Icon blue
  static const Color inputText = Color(0xFFE8F4FD); // Primary text
  static const Color inputLabel = Color(0xFFB8C7D9); // Secondary text
  
  // Card Colors
  static const Color cardBackground = Color(0xFF1A1F35); // Surface background
  static const Color cardBorder = Color(0xFF2A3F5F); // Border light
  
  // Status Indicator Colors
  static const Color listeningIndicator = Color(0xFFFF9800); // Warning orange
  static const Color processingIndicator = Color(0xFF4A90E2); // Icon blue
  static const Color speakingIndicator = Color(0xFF4CAF50); // Success green
  
  // Gradient Colors - Icon-inspired gradients
  static const List<Color> primaryGradient = [
    Color(0xFF4A90E2), // Icon blue
    Color(0xFF6B9BD4), // Secondary blue
  ];
  
  static const List<Color> backgroundGradient = [
    Color(0xFF0A0E21), // Primary background
    Color(0xFF1A1F35), // Surface background
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF4A90E2), // Icon blue
    Color(0xFF64B5F6), // Cyan accent
  ];
  
  // Icon-specific colors
  static const Color iconPrimary = Color(0xFF4A90E2); // Main icon blue
  static const Color iconSecondary = Color(0xFF6B9BD4); // Secondary icon blue
  static const Color iconAccent = Color(0xFF64B5F6); // Icon accent cyan
} 