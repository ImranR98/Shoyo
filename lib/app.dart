import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:shoyo/pages/home_page.dart';
import 'package:shoyo/services/settings_controller.dart';
import 'package:shoyo/theme/app_theme.dart';
import 'package:shoyo/theme/dynamic_color_bridge.dart';

const String kAppVersion = '1.1.0';

class ShoyoApp extends StatelessWidget {
  const ShoyoApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final useDynamic = settings.themeStyle != AppThemeStyle.classic;
            return MaterialApp(
              title: 'Shoyo',
              theme: AppTheme.build(
                settings.themeStyle,
                Brightness.light,
                dynamicScheme: useDynamic
                    ? lightDynamic?.toFlutterColorScheme()
                    : null,
              ),
              darkTheme: AppTheme.build(
                settings.themeStyle,
                Brightness.dark,
                dynamicScheme: useDynamic
                    ? darkDynamic?.toFlutterColorScheme()
                    : null,
              ),
              home: HomePage(settings: settings),
            );
          },
        );
      },
    );
  }
}
