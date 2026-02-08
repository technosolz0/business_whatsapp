import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // --- Light Theme ---
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.cardLight,
      error: AppColors.error,
    ),
    appBarTheme: _buildAppBarTheme(
      backgroundColor: AppColors.cardLight,
      iconColor: AppColors.textPrimaryLight,
      textColor: AppColors.textPrimaryLight,
    ),
    cardTheme: _buildCardTheme(
      color: AppColors.cardLight,
      borderColor: AppColors.borderLight,
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(
      backgroundColor: AppColors.primary,
    ),
    textTheme: _buildTextTheme(
      primaryColor: AppColors.textPrimaryLight,
      secondaryColor: AppColors.textSecondaryLight,
    ),
  );

  // --- Dark Theme ---
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      surface: AppColors.cardDark,
      error: AppColors.errorDark,
    ),
    appBarTheme: _buildAppBarTheme(
      backgroundColor: AppColors.cardDark,
      iconColor: AppColors.textPrimaryDark,
      textColor: AppColors.textPrimaryDark,
    ),
    cardTheme: _buildCardTheme(
      color: AppColors.cardDark,
      borderColor: AppColors.borderDark,
    ),
    elevatedButtonTheme: _buildElevatedButtonTheme(
      backgroundColor: AppColors.primaryDark,
    ),
    textTheme: _buildTextTheme(
      primaryColor: AppColors.textPrimaryDark,
      secondaryColor: AppColors.textSecondaryDark,
    ),
  );

  // --- Common Theme Builders ---

  static AppBarTheme _buildAppBarTheme({
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: iconColor),
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600, // SemiBold
      ),
    );
  }

  static CardThemeData _buildCardTheme({
    required Color color,
    required Color borderColor,
  }) {
    return CardThemeData(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme({
    required Color backgroundColor,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500, // Medium
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600, // SemiBold
          color: primaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600, // SemiBold
          color: primaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600, // SemiBold
          color: primaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400, // Regular
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500, // Medium
          color: secondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400, // Regular
          color: secondaryColor,
        ),
      ),
    );
  }
}
