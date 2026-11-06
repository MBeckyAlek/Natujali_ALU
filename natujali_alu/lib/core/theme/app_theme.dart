import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// App-wide theme so screens get consistent inputs, buttons and text
/// without styling each widget by hand.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
        primary: c.primary,
        error: c.accent,
        surface: c.surface,
      ),
      scaffoldBackgroundColor: c.background,
      extensions: [c],
    );

    final inter = GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: c.ink, displayColor: c.ink);
    final textTheme = inter.copyWith(
      headlineSmall: inter.headlineSmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: inter.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: inter.bodySmall?.copyWith(fontSize: 12, color: c.muted),
      // Used for the small red "eyebrow" labels above page titles (ALU red).
      labelSmall: inter.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: c.accent,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final buttonText = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: c.muted),
        border: inputBorder(c.border),
        enabledBorder: inputBorder(c.border),
        focusedBorder: inputBorder(c.primary, 1.5),
        errorBorder: inputBorder(c.accent),
        focusedErrorBorder: inputBorder(c.accent, 1.5),
        errorStyle: TextStyle(color: c.accent),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.primaryTint,
          disabledForegroundColor: c.primary.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.primary,
          side: BorderSide(color: c.border),
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1),
    );
  }
}
