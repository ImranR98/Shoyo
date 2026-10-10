import 'dart:io';

import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:path/path.dart' as p;

enum SaveStatus { pending, saving, saved, skipped, failed }

class SaveTask {
  SaveTask({
    required this.sourcePath,
    required this.originalName,
    required this.mediaType,
    String? name,
  }) : name = name ?? originalName;

  final String sourcePath;
  final String originalName;
  final SharedMediaType mediaType;

  String name;
  String? savedName;
  String? error;
  SaveStatus status = SaveStatus.pending;

  bool get isSaved => status == SaveStatus.saved;

  static SaveTask? fromSharedFile(SharedFile file) {
    final path = file.value;
    if (path == null || path.isEmpty) return null;
    final isFile = File(path).existsSync();
    if (!isFile &&
        (file.type == SharedMediaType.TEXT ||
            file.type == SharedMediaType.URL ||
            file.type == SharedMediaType.WEB_SEARCH)) {
      return null;
    }
    return SaveTask(
      sourcePath: path,
      originalName: p.basename(path),
      mediaType: file.type,
    );
  }
}
