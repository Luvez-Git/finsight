import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0B1730);
  static const blue = Color(0xFF2563EB);
  static const background = Color(0xFFF6F8FB);
  static const border = Color(0xFFE5EAF1);
  static const text = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const green = Color(0xFF168A52);
  static const amber = Color(0xFFB7791F);
  static const red = Color(0xFFD14343);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        ),
      );
}
