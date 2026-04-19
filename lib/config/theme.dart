import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFF8B1538);
  static const Color primaryRedDark = Color(0xFF6B0F2A);
  static const Color accentRed = Color(0xFFA91D3A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundWhite = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF333333);
  static const Color textGray = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color dividerGray = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        surface: white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryRed,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
