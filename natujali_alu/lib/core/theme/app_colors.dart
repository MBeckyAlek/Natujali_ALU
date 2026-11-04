import 'package:flutter/material.dart';

/// Colour palette based on the ALU brand: navy with a red accent.
class AppColors {
  AppColors._();

  /// ALU navy, used for buttons, selected states and headings accents.
  static const primary = Color(0xFF12307A);
  static const primaryLight = Color(0xFF2F55B0);

  /// ALU red, used sparingly: the Report button, eyebrow labels and errors.
  static const accent = Color(0xFFD7193F);
  static const accentTint = Color(0xFFFDE8EC);

  static const background = Color(0xFFF4F6FB);
  static const surface = Colors.white;
  static const ink = Color(0xFF0F1B3D);
  static const muted = Color(0xFF66708A);
  static const border = Color(0xFFDCE2EF);

  /// Pale navy used for tinted cards, banners and unselected tiles.
  static const primaryTint = Color(0xFFE7ECF8);

  static const amber = Color(0xFFFEF3C7);
  static const amberText = Color(0xFFB45309);
  static const green = Color(0xFFDCFCE7);
  static const greenText = Color(0xFF15803D);
  static const purple = Color(0xFFEDE7FB);
  static const purpleText = Color(0xFF6D28D9);
}
