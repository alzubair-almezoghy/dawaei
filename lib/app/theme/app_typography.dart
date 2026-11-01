import 'package:flutter/material.dart';

abstract final class AppTypography {
  static TextTheme build(Color foreground, Color secondary) {
    TextStyle style(double size, FontWeight weight, {bool muted = false}) =>
        TextStyle(
          fontFamily: 'IBM Plex Sans Arabic',
          fontSize: size,
          fontWeight: weight,
          height: 1.5,
          color: muted ? secondary : foreground,
        );
    return TextTheme(
      headlineLarge: style(32, FontWeight.w600),
      headlineMedium: style(28, FontWeight.w600),
      headlineSmall: style(24, FontWeight.w600),
      titleLarge: style(20, FontWeight.w600),
      titleMedium: style(18, FontWeight.w600),
      titleSmall: style(16, FontWeight.w500),
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(12, FontWeight.w400, muted: true),
      labelLarge: style(14, FontWeight.w600),
      labelMedium: style(12, FontWeight.w500),
      labelSmall: style(11, FontWeight.w500),
    );
  }
}
