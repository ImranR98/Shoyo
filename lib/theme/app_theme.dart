import 'package:flutter/material.dart';

enum AppThemeStyle {
  classic('Classic red'),
  expressive('Material 3 Expressive'),
  system('Material You');

  const AppThemeStyle(this.label);

  final String label;

  static AppThemeStyle fromName(String? name) {
    for (final style in values) {
      if (style.name == name) return style;
    }
    return AppThemeStyle.classic;
  }
}

abstract final class AppTheme {
  static const Color _lightSeed = Colors.red;
  static const Color _darkSeed = Color(0xFFEF5350);

  static ThemeData build(
    AppThemeStyle style,
    Brightness brightness, {
    ColorScheme? dynamicScheme,
  }) {
    final scheme = switch (style) {
      AppThemeStyle.classic => _redScheme(brightness),
      AppThemeStyle.expressive => _expressiveScheme(brightness, dynamicScheme),
      AppThemeStyle.system => dynamicScheme ?? _redScheme(brightness),
    };
    final base = ThemeData(colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: base.textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: const StadiumBorder()),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: scheme.outlineVariant,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ColorScheme _redScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: brightness == Brightness.light ? _lightSeed : _darkSeed,
      brightness: brightness,
    );
  }

  static ColorScheme _expressiveScheme(
    Brightness brightness,
    ColorScheme? dynamicScheme,
  ) {
    final seed =
        dynamicScheme?.primary ??
        (brightness == Brightness.light ? _lightSeed : _darkSeed);
    return ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.expressive,
    );
  }
}
