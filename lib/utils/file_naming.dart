import 'package:path/path.dart' as p;

abstract final class FileNaming {
  static const int maxLength = 255;
  static const int _maxAttempts = 9999;

  /// Returns [desiredName], or the first available variant with a number
  /// suffix in brackets (like "file (1).ext") if the name is taken.
  ///
  /// [takenLowercase] must contain lowercase names only. The check is
  /// case-insensitive because Android's shared storage is.
  static String uniqueName(String desiredName, Set<String> takenLowercase) {
    if (!takenLowercase.contains(desiredName.toLowerCase())) {
      return desiredName;
    }
    final extension = p.extension(desiredName);
    final base = extension.isEmpty
        ? desiredName
        : desiredName.substring(0, desiredName.length - extension.length);
    for (var i = 1; i <= _maxAttempts; i++) {
      final candidate = '$base ($i)$extension';
      if (!takenLowercase.contains(candidate.toLowerCase())) {
        return candidate;
      }
    }
    throw StateError('Could not find an available name for "$desiredName"');
  }

  /// Returns an error message when [name] is not a valid file name.
  static String? validate(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Enter a file name';
    if (trimmed == '.' || trimmed == '..') {
      return 'That file name is not allowed';
    }
    if (trimmed.contains('/') || trimmed.contains('\\')) {
      return 'File names cannot contain slashes';
    }
    if (trimmed.length > maxLength) return 'File name is too long';
    if (RegExp(r'[\x00-\x1f]').hasMatch(trimmed)) {
      return 'File name contains invalid characters';
    }
    return null;
  }
}
