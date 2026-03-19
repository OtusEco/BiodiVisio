import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF4CAE4F);
  static const Color secondary = Color(0xFF327935);

  // Backgrounds
  static const Color background = Color(0xFFF7F7F7);
  static const Color card = Colors.white;
  static const Color inputFill = Color(0xFFF2F2F2);

  // Texte
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.grey;

  // États
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;

  // Bordures
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Colors.black;

  // Markers
  static const Color mapPoint = Colors.blue;
  static const Color mapLine = Colors.orange;
  static const Color mapPolygon = Colors.red;
}

class AppTheme {
  static ThemeData biodivisioTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.error,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
