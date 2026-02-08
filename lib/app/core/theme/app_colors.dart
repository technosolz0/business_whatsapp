import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Light Mode Palette ---
  static const Color primary = Color(0xFF2563EB); // Brand Blue
  static const Color primaryStrong = Color(0xFF1D4ED8); // Blue Strong
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);
  static const Color backgroundLight = Color(0xFFF6F8FC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(
    0xFFE2E8F0,
  ); // Subtle gray border for light mode
  static const Color sectionLight = Color(0xFFF1F5F9);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // --- Dark Mode Palette ---
  static const Color primaryDark = Color(0xFF3B82F6); // Brand Blue
  static const Color primaryStrongDark = Color(0xFF60A5FA); // Blue Strong
  static const Color textPrimaryDark = Color(0xFFE5E7EB);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color cardDark = Color(0xFF111827);
  static const Color borderDark = Color(
    0xFF2D3748,
  ); // Lighter border for better contrast in dark mode
  static const Color sectionDark = Color(0xFF0F172A);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color errorDark = Color(0xFFF87171);

  // Gray Scale (Retained for legacy or specific uses if needed, otherwise optional)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Legacy aliases if needed to avoid breaking changes immediately (mapped to Light)
  // static const Color warning = Color(0xFFFFC107); // Not specified in new palette, keeping if needed
  static const Color warning = Color(0xFFFFC107);
  // --- WhatsApp / Chat Specific Palette ---
  static const Color waGreenEdge = Color(0xFF00A884);
  static const Color waGreenLight = Color(0xFFD9FDD3);
  static const Color waGreenDark = Color(0xFF005C4B);
  static const Color waHeaderLight = Color(0xFFF0F2F5);
  static const Color waHeaderDark = Color(0xFF202C33);
  static const Color waChatBgLight = Color(0xFFF6F8FC);
  static const Color waChatBgDark = Color(0xFF0B141A);
  static const Color waBubbleReceiverLight = Color(0xFFFFFFFF);
  static const Color waBubbleReceiverDark = Color(0xFF202C33);
  static const Color waTextPrimaryLight = Color(0xFF111B21);
  static const Color waTextPrimaryDark = Color(0xFFE9EDEF);
  static const Color waTextSecondaryLight = Color(0xFF667781);
  static const Color waTextSecondaryDark = Color(0xFF8696A0);
  static const Color waDividerLight = Color(0xFFE9EDEF);
  static const Color waDividerDark = Color(0xFF2F3B43);
}
