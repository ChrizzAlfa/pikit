import 'package:flutter/material.dart';
import 'package:pikit/theme/app_colors.dart';


class AppTheme {
  static final theme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.secondary,

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.accent
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.accent.withOpacity(0.05),
      hintStyle: TextStyle(fontSize: 16, color: AppColors.accent.withOpacity(0.4), fontWeight: FontWeight.w900),
      contentPadding: const EdgeInsets.all(19.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.84),
        borderSide: BorderSide.none
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.84),
        borderSide: const BorderSide(
          color: AppColors.accent,
          width: 1
        )
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 32, fontFamily: 'Dirtyline'),
        shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32)
        )
      )
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 24, fontFamily: 'Dirtyline'),
        side: const BorderSide(
          color: AppColors.primary,
          width: 3.21
        ),
      )
    )
  );
}