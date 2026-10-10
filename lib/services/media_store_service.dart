import 'package:flutter/services.dart';

/// Storage backend for saved files. Implemented by [MediaStoreService] and
/// faked in tests.
abstract class FileStore {
  /// Lowercase names already present in the Downloads folder.
  Future<Set<String>> existingDownloadNames();

  /// Returns the lowercase subset of [names] that is already taken.
  ///
  /// This probes each name individually, so it also finds files that
  /// [existingDownloadNames] cannot see.
  Future<Set<String>> takenNames(List<String> names);

  /// Saves [fileName] and returns the name it was actually saved as.
  ///
  /// When [allowProviderRename] is false the save fails with a `CONFLICT`
  /// error instead of letting MediaStore choose a different name.
  Future<String> saveFile({
    required String sourcePath,
    required String fileName,
    required bool allowProviderRename,
  });
}

class MediaStoreService implements FileStore {
  static const MethodChannel _channel = MethodChannel(
    'dev.imranr.shoyo/media_store',
  );

  @override
  Future<Set<String>> existingDownloadNames() async {
    final names =
        await _channel.invokeListMethod<String>('getDownloadNames') ??
        const <String>[];
    return names.map((name) => name.toLowerCase()).toSet();
  }

  @override
  Future<Set<String>> takenNames(List<String> names) async {
    if (names.isEmpty) return <String>{};
    final result =
        await _channel.invokeListMethod<bool>('probeNames', {'names': names}) ??
        const <bool>[];
    final taken = <String>{};
    for (var i = 0; i < names.length && i < result.length; i++) {
      if (result[i]) taken.add(names[i].toLowerCase());
    }
    return taken;
  }

  @override
  Future<String> saveFile({
    required String sourcePath,
    required String fileName,
    required bool allowProviderRename,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>('saveFile', {
      'sourcePath': sourcePath,
      'fileName': fileName,
      'allowProviderRename': allowProviderRename,
    });
    return result?['displayName'] as String? ?? fileName;
  }
}
