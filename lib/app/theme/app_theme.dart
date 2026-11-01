import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_geometry.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = AppColors.pageBackground(brightness);
    final surface = dark ? const Color(0xFF0D3042) : Colors.white;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(
      primary: dark ? AppColors.accent : AppColors.brand,
      onPrimary: dark ? const Color(0xFF073444) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF16596D)
          : const Color(0xFFD9EEF3),
      onPrimaryContainer: dark ? Colors.white : const Color(0xFF123B4A),
      surface: background,
      surfaceContainerLow: surface,
      surfaceContainerHighest: dark
          ? const Color(0xFF164256)
          : const Color(0xFFEEF5F7),
      onSurface: dark ? Colors.white : const Color(0xFF18333F),
      onSurfaceVariant:
          dark ? const Color(0xFFC1D8E2) : const Color(0xFF586D77),
      outline: dark ? const Color(0xFF76A9BA) : const Color(0xFF7199A6),
      outlineVariant: dark ? const Color(0xFF32667D) : const Color(0xFFD4E3E8),
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
    );
    final text = AppTypography.build(scheme.onSurface, scheme.onSurfaceVariant);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'IBM Plex Sans Arabic',
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.button);
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: dark ? Colors.white : const Color(0xFF18333F),
        titleTextStyle: text.titleLarge,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        labelStyle: text.bodyMedium,
        border: OutlineInputBorder(borderRadius: AppRadius.input),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark ? Colors.white : AppColors.brand,
          foregroundColor: dark ? AppColors.brand : Colors.white,
          minimumSize: const Size(48, 52),
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: text.labelLarge,
          foregroundColor: dark ? Colors.white : AppColors.brand,
          side: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.58)
                : AppColors.brand.withValues(alpha: 0.55),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: buttonShape,
        extendedTextStyle: text.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: dark ? AppColors.navigation : Colors.white,
        indicatorColor: dark ? AppColors.accent : const Color(0xFFD9EEF3),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (dark ? const Color(0xFF073444) : AppColors.brand)
                : (dark
                    ? const Color(0xFFB9D7E2)
                    : const Color(0xFF607681)),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color:
                states.contains(WidgetState.selected)
                    ? (dark ? Colors.white : const Color(0xFF18333F))
                    : (dark
                        ? const Color(0xFFB9D7E2)
                        : const Color(0xFF607681)),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.hero),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.input),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
