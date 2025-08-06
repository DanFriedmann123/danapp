import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinanceTheme {
  // Colors
  static Color get primaryColor => const Color(0xFF2563EB);
  static Color get secondaryColor => const Color(0xFF64748B);
  static Color get successColor => const Color(0xFF10B981);
  static Color get dangerColor => const Color(0xFFEF4444);
  static Color get warningColor => const Color(0xFFF59E0B);
  static Color get backgroundColor => const Color(0xFFF8FAFC);
  static Color get cardColor => Colors.white;
  static Color get textPrimary => const Color(0xFF1E293B);
  static Color get textSecondary => const Color(0xFF64748B);
  static Color get textTertiary => const Color(0xFF94A3B8);
  static Color get borderColor => const Color(0xFFE2E8F0);

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get headingSmall => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle get valueLarge => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get valueMedium => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get valueSmall => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get successText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: successColor,
  );

  static TextStyle get dangerText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: dangerColor,
  );

  // Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor, width: 1),
  );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: primaryColor, width: 1),
    ),
  );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // Input Decoration
  static InputDecoration get inputDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    filled: true,
    fillColor: backgroundColor,
  );

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // Padding
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets listItemPadding = EdgeInsets.all(12.0);

  // App Bar Theme
  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: cardColor,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: headingSmall,
  );

  // Floating Action Button Theme
  static FloatingActionButtonThemeData get floatingActionButtonTheme =>
      FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  // Icon Theme
  static IconThemeData get iconTheme =>
      IconThemeData(color: textSecondary, size: 20);

  // Number Formatting Helper
  static String formatCurrency(double amount) {
    if (amount == 0) return '₪0.00';

    // Convert to string with 2 decimal places
    String numStr = amount.toStringAsFixed(2);

    // Split into integer and decimal parts
    List<String> parts = numStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas for thousands separators
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }

    // Handle negative numbers
    if (formattedInteger.startsWith('-')) {
      formattedInteger = '-' + formattedInteger.substring(1);
    }

    return '₪$formattedInteger.$decimalPart';
  }
}
