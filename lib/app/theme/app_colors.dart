import 'package:flutter/material.dart';

abstract final class AppColors {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBackground(Brightness brightness) =>
      brightness == Brightness.dark
          ? darkBackground
          : const Color(0xFFF5F9FA);

  static Color pageSurface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : Colors.white;

  static Color raisedSurface(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF0D3042)
          : const Color(0xFFEEF5F7);

  static Color primaryText(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF18333F);

  static Color mutedText(Brightness brightness) =>
      brightness == Brightness.dark
          ? secondaryText
          : const Color(0xFF617681);

  static Color accentFor(Brightness brightness) =>
      brightness == Brightness.dark ? success(brightness) : brand;

  static Color subtleBorder(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF32667D)
          : const Color(0xFFD8E6EA);

  static LinearGradient pageGradientFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? pageGradient
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FBFC), Color(0xFFEAF4F7)],
              stops: [0, 1],
            );

  static LinearGradient appBarGradientFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? appBarGradient
          : const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Color(0xFFF0F7F9)],
            );

  static const brand = Color(0xFF1684A6);
  static const accent = Colors.white;
  static const mint = Color(0xFF174D62);
  static const background = Color(0xFF0A344B);
  static const slate = Color(0xFFF1F8FB);
  static const softRed = Color(0xFFE57373);
  static const accessibleTeal = brand;
  static const secondaryText = Color(0xFFC3D9E1);
  static const darkBackground = Color(0xFF071F2D);
  static const darkSurface = Color(0xFF10384B);
  static const navigation = Color(0xFF082A3C);
  static const pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF163958), Color(0xFF126A8A), Color(0xFF0C789A)],
    stops: [0, 0.52, 1],
  );
  static const appBarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF123452), Color(0xFF0B6281)],
  );
  static Color success(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF8DE3B2)
          : const Color(0xFF9BEBC0);
  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFFFD17F)
          : const Color(0xFFFFD889);
}
