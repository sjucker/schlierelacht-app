import 'package:flutter/material.dart';

/// The three colors of the Schliere lacht logo.
abstract final class FestColors {
  static const Color yellow = Color(0xFFFFF34E);
  static const Color blue = Color(0xFF2B3585);
  static const Color lightBlue = Color(0xFF7CA6D8);

  /// Very light tints of [lightBlue] for page backgrounds and section headers.
  static const Color lightBlueTint = Color(0xFFE4EDF8);
  static const Color pageBackground = Color(0xFFF3F7FC);

  /// Dark mode: a deep navy derived from [blue] for pages, a lighter one for
  /// cards and section headers.
  static const Color darkPageBackground = Color(0xFF0E1330);
  static const Color darkCard = Color(0xFF1A2148);
  static const Color darkTint = Color(0xFF26306A);
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
  return _festTheme(scheme, pageBackground: FestColors.pageBackground, card: Colors.white);
}

/// The dark counterpart, used when the device is in dark mode. Brand blue on
/// navy would vanish, so [FestColors.lightBlue] takes over as the accent
/// (headings, buttons, icons); the app bar, the home tiles and the yellow
/// highlights keep their logo colors.
ThemeData buildFestDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: FestColors.blue, brightness: Brightness.dark).copyWith(
    primary: FestColors.lightBlue,
    onPrimary: FestColors.darkPageBackground,
    primaryContainer: FestColors.darkTint,
    onPrimaryContainer: Colors.white,
    secondary: FestColors.lightBlue,
    onSecondary: FestColors.darkPageBackground,
    secondaryContainer: FestColors.darkTint,
    onSecondaryContainer: Colors.white,
    tertiary: FestColors.yellow,
    onTertiary: FestColors.blue,
    tertiaryContainer: FestColors.yellow,
    onTertiaryContainer: FestColors.blue,
    surface: FestColors.darkPageBackground,
  );
  return _festTheme(scheme, pageBackground: FestColors.darkPageBackground, card: FestColors.darkCard);
}

ThemeData _festTheme(ColorScheme scheme, {required Color pageBackground, required Color card}) => ThemeData(
  colorScheme: scheme,
  useMaterial3: true,
  scaffoldBackgroundColor: pageBackground,
  // The logo-blue app bar stays in both modes.
  appBarTheme: const AppBarTheme(backgroundColor: FestColors.blue, foregroundColor: Colors.white),
  cardTheme: CardThemeData(color: card, surfaceTintColor: Colors.transparent),
  // Flat search bars in the card color (Programm, Gastro): no M3 drop shadow.
  searchBarTheme: SearchBarThemeData(elevation: const WidgetStatePropertyAll(0), backgroundColor: WidgetStatePropertyAll(card)),
);
