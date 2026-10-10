import 'dart:io';

import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/models/save_task.dart';

void main() {
  test('keeps shared text files that exist on disk', () {
    final file = File('${Directory.systemTemp.path}/shoyo-save-task.txt')
      ..writeAsStringSync('x');
    addTearDown(file.deleteSync);

    final task = SaveTask.fromSharedFile(
      SharedFile(
        value: file.path,
        type: SharedMediaType.TEXT,
        mimeType: 'text/plain',
      ),
    );

    expect(task, isNotNull);
    expect(task!.originalName, 'shoyo-save-task.txt');
  });

  test('ignores shared text that is not a file', () {
    final task = SaveTask.fromSharedFile(
      SharedFile(value: 'hello world', type: SharedMediaType.TEXT),
    );

    expect(task, isNull);
  });

  test('ignores shared urls', () {
    final task = SaveTask.fromSharedFile(
      SharedFile(value: 'https://example.com', type: SharedMediaType.URL),
    );

    expect(task, isNull);
  });

  test('keeps files regardless of the reported media type', () {
    final file = File('${Directory.systemTemp.path}/shoyo-save-task.bin')
      ..writeAsStringSync('x');
    addTearDown(file.deleteSync);

    final task = SaveTask.fromSharedFile(
      SharedFile(value: file.path, type: SharedMediaType.OTHER),
    );

    expect(task, isNotNull);
  });
}
