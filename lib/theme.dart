import 'package:flutter/material.dart';

/// Calm, parent-facing palette: sage, cream, and restrained alerts.
abstract final class BtColors {
  static const sage = Color(0xFF2F6F6A);
  static const sageDark = Color(0xFF1C3D3A);
  static const sageSoft = Color(0xFFD7E8E4);
  static const cream = Color(0xFFF7F3EC);
  static const sand = Color(0xFFE8DFD0);
  static const ink = Color(0xFF1B2A28);
  static const muted = Color(0xFF5E6F6C);
  static const gold = Color(0xFFC9923A);
  static const coral = Color(0xFFC45C4A);
  static const greenZone = Color(0xFF2E8B6A);
  static const yellowZone = Color(0xFFD4A017);
  static const redZone = Color(0xFFC44536);
}

ThemeData buildBronchTheme() {
  const seed = BtColors.sage;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    primary: BtColors.sage,
    onPrimary: Colors.white,
    secondary: BtColors.sageDark,
    surface: Colors.white,
    error: BtColors.coral,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BtColors.cream,
    visualDensity: VisualDensity.standard,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: BtColors.cream,
      foregroundColor: BtColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: BtColors.ink,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x1A1B2A28)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: BtColors.sageSoft,
      side: const BorderSide(color: Color(0x331B2A28)),
      labelStyle: const TextStyle(fontSize: 13, color: BtColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BtColors.sage,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BtColors.sageDark,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: BtColors.sageSoft,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFFF3EEE4),
      indicatorColor: BtColors.sageSoft,
      selectedIconTheme: IconThemeData(color: BtColors.sageDark),
      selectedLabelTextStyle: TextStyle(
        color: BtColors.sageDark,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFBF8F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x331B2A28)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x331B2A28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BtColors.sage, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BtColors.sage,
      foregroundColor: Colors.white,
    ),
    dividerColor: const Color(0x1A1B2A28),
  );
}
