import 'package:flutter/services.dart';
import 'package:shoyo/models/save_task.dart';
import 'package:shoyo/services/media_store_service.dart';
import 'package:shoyo/utils/file_naming.dart';

class FileSaver {
  FileSaver(this._fileStore);

  final FileStore _fileStore;

  /// Best-effort set of taken names (lowercase) combining the MediaStore
  /// listing with per-name probes, so conflicts are found even when the
  /// listing cannot see files created by other apps.
  Future<Set<String>> knownTakenNames(List<SaveTask> tasks) async {
    final taken = <String>{};
    try {
      taken.addAll(await _fileStore.existingDownloadNames());
    } catch (_) {
      // Fall through to the probes below.
    }
    try {
      taken.addAll(
        await _fileStore.takenNames(tasks.map((task) => task.name).toList()),
      );
    } catch (_) {
      // Probes are best-effort; saving still refuses silent renames.
    }
    return taken;
  }

  Future<Set<String>> existingNames() => _fileStore.existingDownloadNames();

  /// Saves every task to Downloads.
  ///
  /// When [autoRename] is true, names that conflict with [knownTaken] (or
  /// with an earlier task in the same batch) are given a number suffix.
  /// When it is false, MediaStore is not allowed to rename silently.
  Future<void> save(
    List<SaveTask> tasks, {
    required bool autoRename,
    Set<String>? knownTaken,
    void Function()? onProgress,
  }) async {
    final taken = <String>{...?knownTaken};
    try {
      taken.addAll(await _fileStore.existingDownloadNames());
    } catch (_) {
      // The provided set (from probes) is still used.
    }
    for (final task in tasks) {
      if (autoRename && taken.contains(task.name.toLowerCase())) {
        task.name = FileNaming.uniqueName(task.name, taken);
      }
      taken.add(task.name.toLowerCase());
    }

    for (final task in tasks) {
      task.status = SaveStatus.saving;
      onProgress?.call();
      try {
        final savedName = await _fileStore.saveFile(
          sourcePath: task.sourcePath,
          fileName: task.name,
          allowProviderRename: autoRename,
        );
        task.savedName = savedName;
        task.status = SaveStatus.saved;
      } on PlatformException catch (e) {
        task.error = e.code == 'CONFLICT'
            ? 'A file with this name already exists'
            : e.message ?? e.code;
        task.status = SaveStatus.failed;
      } on Exception catch (e) {
        task.error = e.toString();
        task.status = SaveStatus.failed;
      }
      onProgress?.call();
    }
  }
}
