import 'package:flutter/material.dart';

/// The three colors of the Schliere lacht logo.
abstract final class FestColors {
  static const Color yellow = Color(0xFFFFF34E);
  static const Color blue = Color(0xFF2B3585);
  static const Color lightBlue = Color(0xFF7CA6D8);

  /// Very light tints of [lightBlue] for page backgrounds and section headers.
  static const Color lightBlueTint = Color(0xFFE4EDF8);
  static const Color pageBackground = Color(0xFFF3F7FC);
}

/// App theme built on the logo colors: blue as primary (app bars, buttons,
/// accents), light blue as secondary (section headers, chips) and yellow as
/// tertiary (highlights). Pages sit on a faint blue tint with white cards, so
/// the app doesn't read as gray.
ThemeData buildFestTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: FestColors.blue).copyWith(
    primary: FestColors.blue,
    onPrimary: Colors.white,
    primaryContainer: FestColors.lightBlueTint,
    onPrimaryContainer: FestColors.blue,
    secondary: FestColors.lightBlue,
    onSecondary: FestColors.blue,
    secondaryContainer: FestColors.lightBlueTint,
    onSecondaryContainer: FestColors.blue,
    tertiary: FestColors.yellow,
    onTertiary: FestColors.blue,
    tertiaryContainer: FestColors.yellow,
    onTertiaryContainer: FestColors.blue,
    surface: FestColors.pageBackground,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: FestColors.pageBackground,
    appBarTheme: const AppBarTheme(backgroundColor: FestColors.blue, foregroundColor: Colors.white),
    cardTheme: const CardThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    // Flat, white search bars (Programm, Gastro): no M3 drop shadow.
    searchBarTheme: const SearchBarThemeData(elevation: WidgetStatePropertyAll(0), backgroundColor: WidgetStatePropertyAll(Colors.white)),
  );
}
