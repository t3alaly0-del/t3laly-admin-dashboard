import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same brand palette as the mobile app (kept in sync manually — if this
/// ever bugs you, it's a good candidate to move into the `shared` package
/// alongside the models).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0E5685);
  static const primaryDark = Color(0xFF073A5C);
  static const blue = Color(0xFF6FC9EC);
  static const blueLight = Color(0xFFE7F7FD);
  static const yellow = Color(0xFFF7D042);
  static const yellowDark = Color(0xFFE0B82A);
  static const red = Color(0xFFE8463A);
  static const redDark = Color(0xFFC73629);
  static const ink = Color(0xFF07304A);
  static const surface = Color(0xFFF4F8FB);
  static const border = Color(0xFFE2E8F0);
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base) =>
      GoogleFonts.cairoTextTheme(base).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  static ThemeData get theme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      primaryColor: AppColors.primary,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.yellow,
        error: AppColors.red,
        surface: Colors.white,
      ),
      textTheme: _textTheme(base.textTheme),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}
