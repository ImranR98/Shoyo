import 'package:flutter/material.dart';
import 'package:shoyo/app.dart';
import 'package:shoyo/services/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController(SharedPrefsStore());
  await settings.load();
  runApp(ShoyoApp(settings: settings));
}
