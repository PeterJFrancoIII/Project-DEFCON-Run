// Jobs v2 - Sentinel Theme
// Consistent black/yellow military-grade styling

import 'package:flutter/material.dart';

/// Sentinel Jobs Theme - Dark military aesthetic
class SentinelJobsTheme {
  // Core Colors
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFFFFEB3B); // Sentinel Yellow
  static const Color primaryDark = Color(0xFFD4C12A);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF888888);
  static const Color textMuted = Color(0xFF666666);

  // DEFCON Colors
  static const Color defcon1 = Color(0xFFFF0000);
  static const Color defcon2 = Color(0xFFFF6600);
  static const Color defcon3 = Color(0xFFFFEB3B);
  static const Color defcon4 = Color(0xFF4CAF50);
  static const Color defcon5 = Color(0xFF2196F3);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5252);
  static const Color critical = Color(0xFFFF0000);

  /// Get DEFCON color by level
  static Color getDefconColor(int level) {
    switch (level) {
      case 1:
        return defcon1;
      case 2:
        return defcon2;
      case 3:
        return defcon3;
      case 4:
        return defcon4;
      case 5:
        return defcon5;
      default:
        return defcon5;
    }
  }

  /// Get urgency color
  static Color getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return critical;
      case 'high':
        return warning;
      case 'normal':
      case 'available':
      default:
        return success;
    }
  }

  /// Standard card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: surfaceLight, width: 0.5),
  );

  /// Input decoration for text fields
  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textSecondary),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: textSecondary),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: error),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: surfaceLight,
    );
  }

  /// Primary button style
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: background,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Secondary button style
  static ButtonStyle secondaryButton = OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  /// Header text style
  static const TextStyle headerStyle = TextStyle(
    color: primary,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
  );

  /// Title text style
  static const TextStyle titleStyle = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// Body text style
  static const TextStyle bodyStyle = TextStyle(
    color: textPrimary,
    fontSize: 14,
  );

  /// Muted text style
  static const TextStyle mutedStyle = TextStyle(
    color: textMuted,
    fontSize: 12,
  );
}
