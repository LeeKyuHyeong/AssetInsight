import 'package:flutter/material.dart';

/// 앱 색상 상수
class AppColors {
  static const Color background = Color(0xFF0A0E14);
  static const Color cardBackground = Color(0xFF141E2B);
  static const Color primary = Color(0xFF1E3A5F);
  static const Color accent = Color(0xFF00FF00);
  static const Color terran = Color(0xFFCC0000);
  static const Color zerg = Color(0xFF9900CC);
  static const Color protoss = Color(0xFFFFCC00);
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF8899AA);
}

class AppTheme {
  // 스타크래프트 테마 색상
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color accentGreen = Color(0xFF00FF00);
  static const Color terranRed = Color(0xFFCC0000);
  static const Color zergPurple = Color(0xFF9900CC);
  static const Color protossYellow = Color(0xFFFFCC00);
  static const Color backgroundDark = Color(0xFF0A0E14);
  static const Color cardBackground = Color(0xFF141E2B);
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF8899AA);

  // 등급별 색상
  static Color getGradeColor(String grade) {
    if (grade.startsWith('SSS')) return const Color(0xFFFF0000);
    if (grade.startsWith('SS')) return const Color(0xFFFF6600);
    if (grade.startsWith('S')) return const Color(0xFFFFCC00);
    if (grade.startsWith('A')) return const Color(0xFF00CC00);
    if (grade.startsWith('B')) return const Color(0xFF0099FF);
    if (grade.startsWith('C')) return const Color(0xFF9966FF);
    if (grade.startsWith('D')) return const Color(0xFF999999);
    if (grade.startsWith('E')) return const Color(0xFF666666);
    return const Color(0xFF444444); // F
  }

  // 종족별 색상
  static Color getRaceColor(String race) {
    switch (race.toLowerCase()) {
      case 'terran':
      case 't':
        return terranRed;
      case 'zerg':
      case 'z':
        return zergPurple;
      case 'protoss':
      case 'p':
        return protossYellow;
      default:
        return textPrimary;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentGreen,
        surface: cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A3A4A),
        thickness: 1,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: textSecondary,
        indicatorColor: accentGreen,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
}
