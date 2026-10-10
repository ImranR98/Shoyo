import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/models/save_task.dart';
import 'package:shoyo/pages/filename_editor_page.dart';

SaveTask task(String name, {String? originalName}) => SaveTask(
  sourcePath: '/cache/$name',
  originalName: originalName ?? name,
  mediaType: SharedMediaType.FILE,
  name: name,
);

Future<void> pumpEditor(
  WidgetTester tester, {
  required List<SaveTask> tasks,
  required Set<String> existingNames,
  void Function(List<SaveTask>?)? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<List<SaveTask>>(
                  MaterialPageRoute(
                    builder: (context) => FilenameEditorPage(
                      tasks: tasks,
                      existingNames: existingNames,
                    ),
                  ),
                );
                onResult?.call(result);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

FilledButton saveButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

void main() {
  testWidgets('shows a hint and allows saving for a prefilled conflict', (
    tester,
  ) async {
    List<SaveTask>? result;
    await pumpEditor(
      tester,
      tasks: [task('photo (1).jpg', originalName: 'photo.jpg')],
      existingNames: {'photo.jpg'},
      onResult: (value) => result = value,
    );

    expect(find.text('Original "photo.jpg" already exists'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.single.name, 'photo (1).jpg');
  });

  testWidgets('disables save when the conflicting original is restored', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      tasks: [task('photo (1).jpg', originalName: 'photo.jpg')],
      existingNames: {'photo.jpg'},
    );

    await tester.enterText(find.byType(TextFormField), 'photo.jpg');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNull);
    expect(find.text('A file with this name already exists'), findsNothing);
    expect(find.text('Original "photo.jpg" already exists'), findsOneWidget);
  });

  testWidgets('disables save and hints when a name is edited into a conflict', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      tasks: [task('a.txt'), task('b.txt')],
      existingNames: <String>{},
    );

    await tester.enterText(find.byType(TextFormField).first, 'b.txt');
    await tester.pump();

    expect(saveButton(tester).onPressed, isNull);
    expect(find.text('This name is already taken'), findsWidgets);
  });

  testWidgets('shows a format error and disables save for an empty name', (
    tester,
  ) async {
    await pumpEditor(tester, tasks: [task('a.txt')], existingNames: <String>{});

    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();

    expect(find.text('Enter a file name'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('applies a suggestion with the wand button', (tester) async {
    List<SaveTask>? result;
    await pumpEditor(
      tester,
      tasks: [task('photo.jpg')],
      existingNames: {'photo.jpg'},
      onResult: (value) => result = value,
    );

    expect(find.byIcon(Icons.auto_fix_high_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.auto_fix_high_outlined));
    await tester.pump();

    expect(find.text('photo (1).jpg'), findsOneWidget);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.single.name, 'photo (1).jpg');
  });

  testWidgets('returns manually edited names', (tester) async {
    List<SaveTask>? result;
    await pumpEditor(
      tester,
      tasks: [task('photo.jpg')],
      existingNames: <String>{},
      onResult: (value) => result = value,
    );

    await tester.enterText(find.byType(TextFormField), 'holiday.jpg');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Save 1 file'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.single.name, 'holiday.jpg');
  });
}
