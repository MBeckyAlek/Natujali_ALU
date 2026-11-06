import 'package:flutter/material.dart';

/// Colour palette based on the ALU brand: navy with a red accent.
///
/// There is one palette for light mode and one for dark mode. Screens read
/// the active one with `context.colors`, so they follow the theme setting.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryTint,
    required this.accent,
    required this.accentTint,
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.border,
    required this.amber,
    required this.amberText,
    required this.green,
    required this.greenText,
    required this.purple,
    required this.purpleText,
    required this.chartOpened,
    required this.chartResolved,
  });

  /// ALU navy, used for buttons, selected states and links.
  final Color primary;
  final Color primaryLight;

  /// Pale navy used for tinted cards, banners and unselected tiles.
  final Color primaryTint;

  /// ALU red, used sparingly: the Report button, eyebrow labels and errors.
  final Color accent;
  final Color accentTint;

  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color border;

  final Color amber;
  final Color amberText;
  final Color green;
  final Color greenText;
  final Color purple;
  final Color purpleText;

  /// Line colours for the staff activity chart, checked for colour-blind
  /// separation against each mode's surface.
  final Color chartOpened;
  final Color chartResolved;

  static const light = AppPalette(
    primary: Color(0xFF12307A),
    primaryLight: Color(0xFF2F55B0),
    primaryTint: Color(0xFFE7ECF8),
    accent: Color(0xFFD7193F),
    accentTint: Color(0xFFFDE8EC),
    background: Color(0xFFF4F6FB),
    surface: Colors.white,
    ink: Color(0xFF0F1B3D),
    muted: Color(0xFF66708A),
    border: Color(0xFFDCE2EF),
    amber: Color(0xFFFEF3C7),
    amberText: Color(0xFFB45309),
    green: Color(0xFFDCFCE7),
    greenText: Color(0xFF15803D),
    purple: Color(0xFFEDE7FB),
    purpleText: Color(0xFF6D28D9),
    chartOpened: Color(0xFF2F55B0),
    chartResolved: Color(0xFF15803D),
  );

  /// Navy is too dark to read on a dark background, so dark mode uses a
  /// lighter blue and softer tints.
  static const dark = AppPalette(
    primary: Color(0xFF5A7FE0),
    primaryLight: Color(0xFF3A5BB8),
    primaryTint: Color(0xFF1E2A4A),
    accent: Color(0xFFFF5470),
    accentTint: Color(0xFF3A1C27),
    background: Color(0xFF0E1424),
    surface: Color(0xFF182036),
    ink: Color(0xFFE8ECF6),
    muted: Color(0xFF9AA3BA),
    border: Color(0xFF2A3450),
    amber: Color(0xFF3A2E10),
    amberText: Color(0xFFFBBF24),
    green: Color(0xFF10301F),
    greenText: Color(0xFF4ADE80),
    purple: Color(0xFF2B2250),
    purpleText: Color(0xFFC4B5FD),
    chartOpened: Color(0xFF5A7FE0),
    chartResolved: Color(0xFF16A34A),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: mix(primary, other.primary),
      primaryLight: mix(primaryLight, other.primaryLight),
      primaryTint: mix(primaryTint, other.primaryTint),
      accent: mix(accent, other.accent),
      accentTint: mix(accentTint, other.accentTint),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      border: mix(border, other.border),
      amber: mix(amber, other.amber),
      amberText: mix(amberText, other.amberText),
      green: mix(green, other.green),
      greenText: mix(greenText, other.greenText),
      purple: mix(purple, other.purple),
      purpleText: mix(purpleText, other.purpleText),
      chartOpened: mix(chartOpened, other.chartOpened),
      chartResolved: mix(chartResolved, other.chartResolved),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The palette for the current light/dark theme.
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
