import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/pages/home_page.dart';
import 'package:shoyo/services/file_saver.dart';
import 'package:shoyo/services/settings_controller.dart';

import '../helpers/fakes.dart';

Future<SettingsController> settingsWith({bool visited = false}) async {
  final store = FakeKeyValueStore();
  if (visited) {
    store.values[SettingsController.hasVisitedSettingsKey] = true;
  }
  final settings = SettingsController(store);
  await settings.load();
  return settings;
}

Future<void> pumpHome(
  WidgetTester tester, {
  required SettingsController settings,
  required FakeSharingService sharing,
  required FakeFileStore store,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomePage(
        settings: settings,
        sharing: sharing,
        fileSaver: FileSaver(store),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the settings hint on first run', (tester) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    await pumpHome(
      tester,
      settings: await settingsWith(),
      sharing: sharing,
      store: FakeFileStore(),
    );

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Make Shoyo yours'), findsOneWidget);
  });

  testWidgets('hides the hint after settings have been visited', (
    tester,
  ) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    await pumpHome(
      tester,
      settings: await settingsWith(visited: true),
      sharing: sharing,
      store: FakeFileStore(),
    );

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect(find.text('Make Shoyo yours'), findsNothing);
  });

  testWidgets('hides the hint after visiting settings', (tester) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    await pumpHome(
      tester,
      settings: await settingsWith(),
      sharing: sharing,
      store: FakeFileStore(),
    );

    expect(find.text('Make Shoyo yours'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('App colours'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Make Shoyo yours'), findsNothing);
  });

  testWidgets('pre-fills the auto-renamed name in review mode', (tester) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    final settings = await settingsWith();
    await settings.setPromptForFilenames(true);
    await pumpHome(
      tester,
      settings: settings,
      sharing: sharing,
      store: FakeFileStore(existing: {'a.txt'}),
    );

    sharing.emit([
      SharedFile(value: '/cache/a.txt', type: SharedMediaType.FILE),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Review file names'), findsWidgets);
    expect(find.text('a (1).txt'), findsOneWidget);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(find.text('1 file saved'), findsOneWidget);
  });

  testWidgets('auto-renames a conflict without prompting', (tester) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    await pumpHome(
      tester,
      settings: await settingsWith(),
      sharing: sharing,
      store: FakeFileStore(existing: {'a.txt'}),
    );

    sharing.emit([
      SharedFile(value: '/cache/a.txt', type: SharedMediaType.FILE),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('1 file saved'), findsOneWidget);
    expect(find.text('a (1).txt'), findsOneWidget);
  });

  testWidgets('opens the editor when review-before-saving is enabled', (
    tester,
  ) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    final settings = await settingsWith();
    await settings.setPromptForFilenames(true);
    await pumpHome(
      tester,
      settings: settings,
      sharing: sharing,
      store: FakeFileStore(),
    );

    sharing.emit([
      SharedFile(value: '/cache/a.txt', type: SharedMediaType.FILE),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Review file names'), findsWidgets);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(find.text('1 file saved'), findsOneWidget);
  });

  testWidgets('forces the editor for conflicts when auto-rename is off', (
    tester,
  ) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    final settings = await settingsWith();
    await settings.setAutoRenameOnConflict(false);
    await pumpHome(
      tester,
      settings: settings,
      sharing: sharing,
      store: FakeFileStore(existing: {'a.txt'}),
    );

    sharing.emit([
      SharedFile(value: '/cache/a.txt', type: SharedMediaType.FILE),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Review file names'), findsWidgets);
    expect(find.text('a (1).txt'), findsOneWidget);
    expect(find.text('Original "a.txt" already exists'), findsOneWidget);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(find.text('1 file saved'), findsOneWidget);
  });

  testWidgets('reviews only conflicting files when review and auto are off', (
    tester,
  ) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    final settings = await settingsWith();
    await settings.setAutoRenameOnConflict(false);
    await pumpHome(
      tester,
      settings: settings,
      sharing: sharing,
      store: FakeFileStore(existing: {'a.txt'}),
    );

    sharing.emit([
      SharedFile(value: '/cache/a.txt', type: SharedMediaType.FILE),
      SharedFile(value: '/cache/b.txt', type: SharedMediaType.FILE),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Review file names'), findsWidgets);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('a (1).txt'), findsOneWidget);
    expect(find.text('b.txt'), findsNothing);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(find.text('2 files saved'), findsOneWidget);
    expect(find.text('a (1).txt'), findsOneWidget);
    expect(find.text('b.txt'), findsOneWidget);
  });

  testWidgets('keeps clean files and skips cancelled conflicts', (
    tester,
  ) async {
    final sharing = FakeSharingService();
    addTearDown(sharing.dispose);
    final settings = await settingsWith();
    await settings.setAutoRenameOnConflict(false);
    await pumpHome(
      tester,
      settings: settings,
      sharing: sharing,
      store: FakeFileStore(existing: {'a.txt'}),
    );

    sharing.emit([
      SharedFile(value: '/cache/a.txt', type: SharedMediaType.FILE),
      SharedFile(value: '/cache/b.txt', type: SharedMediaType.FILE),
    ]);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 files saved'), findsOneWidget);
    expect(find.text('Not saved'), findsOneWidget);
    expect(find.text('a.txt'), findsOneWidget);
    expect(find.text('b.txt'), findsOneWidget);
  });
}
