import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/models/save_task.dart';
import 'package:shoyo/services/file_saver.dart';

import 'helpers/fakes.dart';

SaveTask task(String name) => SaveTask(
  sourcePath: '/cache/$name',
  originalName: name,
  mediaType: SharedMediaType.FILE,
);

void main() {
  test('auto-renames conflicts when enabled', () async {
    final store = FakeFileStore(existing: {'photo.jpg'});
    final saver = FileSaver(store);
    final tasks = [task('photo.jpg')];

    await saver.save(tasks, autoRename: true);

    expect(tasks.single.status, SaveStatus.saved);
    expect(tasks.single.savedName, 'photo (1).jpg');
    expect(store.saved['/cache/photo.jpg'], 'photo (1).jpg');
  });

  test('renames duplicates inside the same batch', () async {
    final store = FakeFileStore();
    final saver = FileSaver(store);
    final tasks = [task('doc.txt'), task('doc.txt')];

    await saver.save(tasks, autoRename: true);

    expect(tasks[0].savedName, 'doc.txt');
    expect(tasks[1].savedName, 'doc (1).txt');
  });

  test('keeps names when there is no conflict', () async {
    final store = FakeFileStore();
    final saver = FileSaver(store);
    final tasks = [task('holiday.jpg')];

    await saver.save(tasks, autoRename: false);

    expect(tasks.single.savedName, 'holiday.jpg');
  });

  test('marks tasks as failed when saving throws', () async {
    final store = FakeFileStore()..failOnSave = true;
    final saver = FileSaver(store);
    final tasks = [task('photo.jpg')];

    await saver.save(tasks, autoRename: true);

    expect(tasks.single.status, SaveStatus.failed);
    expect(tasks.single.error, isNotNull);
  });

  test('refuses a silent rename when auto-rename is off', () async {
    final store = FakeFileStore(existing: {'photo.jpg'});
    final saver = FileSaver(store);
    final tasks = [task('photo.jpg')];

    await saver.save(tasks, autoRename: false);

    expect(tasks.single.status, SaveStatus.failed);
    expect(tasks.single.error, 'A file with this name already exists');
    expect(store.saved, isEmpty);
  });
}
