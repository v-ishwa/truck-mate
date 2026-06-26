import 'package:flutter/material.dart';

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;
  
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 20.0;
}

class AppTheme {
  static const Color primaryColor = Color(0xFF0095F6);
  static const Color darkBlueColor = Color(0xFF0D47A1);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: primaryColor,
        primary: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1C1C1C),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1C1C1C)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1C)),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Color(0xFF1C1C1C)),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Color(0xFF555555)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF888888)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryColor,
        primary: primaryColor,
        surface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Colors.white54),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white30),
      ),
    );
  }
}
