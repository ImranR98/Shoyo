import 'package:flutter_test/flutter_test.dart';
import 'package:shoyo/utils/file_naming.dart';

void main() {
  group('uniqueName', () {
    test('keeps the name when it is free', () {
      expect(FileNaming.uniqueName('photo.jpg', {}), 'photo.jpg');
    });

    test('adds a number suffix when the name is taken', () {
      expect(
        FileNaming.uniqueName('photo.jpg', {'photo.jpg'}),
        'photo (1).jpg',
      );
    });

    test('skips to the next number when suffixes are taken', () {
      expect(
        FileNaming.uniqueName('photo.jpg', {'photo.jpg', 'photo (1).jpg'}),
        'photo (2).jpg',
      );
    });

    test('is case-insensitive', () {
      expect(
        FileNaming.uniqueName('Photo.JPG', {'photo.jpg'}),
        'Photo (1).JPG',
      );
    });

    test('handles names with multiple dots', () {
      expect(
        FileNaming.uniqueName('archive.tar.gz', {'archive.tar.gz'}),
        'archive.tar (1).gz',
      );
    });

    test('handles names without an extension', () {
      expect(FileNaming.uniqueName('notes', {'notes'}), 'notes (1)');
    });

    test('handles dotfiles', () {
      expect(FileNaming.uniqueName('.nomedia', {'.nomedia'}), '.nomedia (1)');
    });
  });

  group('validate', () {
    test('accepts a normal name', () {
      expect(FileNaming.validate('photo.jpg'), isNull);
    });

    test('rejects empty names', () {
      expect(FileNaming.validate('   '), isNotNull);
    });

    test('rejects path separators', () {
      expect(FileNaming.validate('a/b.txt'), isNotNull);
      expect(FileNaming.validate(r'a\b.txt'), isNotNull);
    });

    test('rejects dot and dot dot', () {
      expect(FileNaming.validate('.'), isNotNull);
      expect(FileNaming.validate('..'), isNotNull);
    });
  });
}
