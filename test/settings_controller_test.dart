import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/services/settings_controller.dart';
import 'package:shoyo/theme/app_theme.dart';

import 'helpers/fakes.dart';

void main() {
  test('uses defaults when nothing is stored', () async {
    final controller = SettingsController(FakeKeyValueStore());
    await controller.load();

    expect(controller.promptForFilenames, isFalse);
    expect(controller.autoRenameOnConflict, isTrue);
    expect(controller.hasVisitedSettings, isFalse);
    expect(controller.themeStyle, AppThemeStyle.classic);
  });

  test('persists and reloads each setting', () async {
    final store = FakeKeyValueStore();
    final controller = SettingsController(store);
    await controller.load();

    await controller.setPromptForFilenames(true);
    await controller.setAutoRenameOnConflict(false);
    await controller.markSettingsVisited();
    await controller.setThemeStyle(AppThemeStyle.expressive);

    expect(store.values[SettingsController.promptForFilenamesKey], isTrue);
    expect(store.values[SettingsController.autoRenameOnConflictKey], isFalse);
    expect(store.values[SettingsController.hasVisitedSettingsKey], isTrue);
    expect(store.strings[SettingsController.themeStyleKey], 'expressive');

    final reloaded = SettingsController(store);
    await reloaded.load();

    expect(reloaded.promptForFilenames, isTrue);
    expect(reloaded.autoRenameOnConflict, isFalse);
    expect(reloaded.hasVisitedSettings, isTrue);
    expect(reloaded.themeStyle, AppThemeStyle.expressive);
  });

  test('notifies listeners on change', () async {
    final controller = SettingsController(FakeKeyValueStore());
    await controller.load();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setPromptForFilenames(true);
    await controller.setPromptForFilenames(true);

    expect(notifications, 1);
  });
}
