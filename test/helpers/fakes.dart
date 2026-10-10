import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:shoyo/services/media_store_service.dart';
import 'package:shoyo/services/settings_controller.dart';
import 'package:shoyo/services/sharing_service.dart';
import 'package:shoyo/utils/file_naming.dart';

class FakeKeyValueStore implements KeyValueStore {
  final Map<String, bool> values = {};
  final Map<String, String> strings = {};

  @override
  Future<bool?> getBool(String key) async => values[key];

  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;

  @override
  Future<String?> getString(String key) async => strings[key];

  @override
  Future<void> setString(String key, String value) async =>
      strings[key] = value;
}

class FakeSharingService implements SharingService {
  final StreamController<List<SharedFile>> _controller =
      StreamController<List<SharedFile>>.broadcast();

  void emit(List<SharedFile> files) => _controller.add(files);

  @override
  Stream<List<SharedFile>> get stream => _controller.stream;

  @override
  Future<List<SharedFile>> initial() async => const [];

  @override
  Future<void> reset() async {}

  Future<void> dispose() => _controller.close();
}

/// Emulates MediaStore: duplicate names get a " (1)" suffix unless
/// [FileStore.saveFile] is called with `allowProviderRename: false`.
class FakeFileStore implements FileStore {
  FakeFileStore({Set<String>? existing}) : existing = existing ?? <String>{};

  final Set<String> existing;
  final Map<String, String> saved = {};
  bool failOnSave = false;

  @override
  Future<Set<String>> existingDownloadNames() async => Set<String>.of(existing);

  @override
  Future<Set<String>> takenNames(List<String> names) async =>
      names.map((name) => name.toLowerCase()).where(existing.contains).toSet();

  @override
  Future<String> saveFile({
    required String sourcePath,
    required String fileName,
    required bool allowProviderRename,
  }) async {
    if (failOnSave) {
      throw Exception('Could not save');
    }
    final lower = fileName.toLowerCase();
    if (existing.contains(lower)) {
      if (!allowProviderRename) {
        throw PlatformException(
          code: 'CONFLICT',
          message: 'A file with this name already exists',
        );
      }
      final renamed = FileNaming.uniqueName(fileName, existing);
      existing.add(renamed.toLowerCase());
      saved[sourcePath] = renamed;
      return renamed;
    }
    existing.add(lower);
    saved[sourcePath] = fileName;
    return fileName;
  }
}
