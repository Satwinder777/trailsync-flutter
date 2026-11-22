import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: AppColors.mutedInk, height: 1.45),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
    );
  }
}
