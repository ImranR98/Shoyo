import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/theme/app_theme.dart';

void main() {
  final dynamicScheme = ColorScheme.fromSeed(seedColor: Colors.blue);

  test('classic style ignores the dynamic scheme', () {
    final classic = AppTheme.build(
      AppThemeStyle.classic,
      Brightness.light,
      dynamicScheme: dynamicScheme,
    );
    final expected = AppTheme.build(AppThemeStyle.classic, Brightness.light);

    expect(classic.colorScheme.primary, expected.colorScheme.primary);
  });

  test('expressive style uses the dynamic seed when available', () {
    final themed = AppTheme.build(
      AppThemeStyle.expressive,
      Brightness.light,
      dynamicScheme: dynamicScheme,
    );
    final fallback = AppTheme.build(AppThemeStyle.expressive, Brightness.light);

    expect(themed.colorScheme.primary, isNot(fallback.colorScheme.primary));
  });

  test('system style uses the dynamic scheme as-is', () {
    final themed = AppTheme.build(
      AppThemeStyle.system,
      Brightness.light,
      dynamicScheme: dynamicScheme,
    );

    expect(themed.colorScheme.primary, dynamicScheme.primary);
  });
}
