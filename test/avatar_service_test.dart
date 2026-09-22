import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/avatar_service.dart';

/// Same shape as id_document_service_test.dart: the file-picking checks run on
/// just a name and a size, before any upload is attempted.
void main() {
  const service = AvatarService();

  group('AvatarService.validate', () {
    test('accepts each allowed image type', () {
      for (final name in ['a.png', 'a.jpg', 'a.jpeg', 'a.webp']) {
        expect(() => service.validate(fileName: name, sizeBytes: 1000), returnsNormally, reason: name);
      }
    });

    test('accepts a file exactly at the 5MB limit', () {
      expect(
        () => service.validate(fileName: 'a.png', sizeBytes: AvatarService.maxBytes),
        returnsNormally,
      );
    });

    test('rejects a file one byte over the limit', () {
      expect(
        () => service.validate(fileName: 'a.png', sizeBytes: AvatarService.maxBytes + 1),
        throwsA(isA<AvatarTooLarge>()),
      );
    });

    test('rejects a disallowed type -- including PDF, which ID documents accept', () {
      expect(() => service.validate(fileName: 'a.pdf', sizeBytes: 1000), throwsA(isA<AvatarInvalidType>()));
      expect(() => service.validate(fileName: 'a.gif', sizeBytes: 1000), throwsA(isA<AvatarInvalidType>()));
      expect(() => service.validate(fileName: 'a.exe', sizeBytes: 1000), throwsA(isA<AvatarInvalidType>()));
    });

    test('rejects a file with no extension', () {
      expect(() => service.validate(fileName: 'photo', sizeBytes: 1000), throwsA(isA<AvatarInvalidType>()));
    });

    test('is case-insensitive about the extension', () {
      expect(() => service.validate(fileName: 'PHOTO.JPG', sizeBytes: 1000), returnsNormally);
    });

    test('checks the type before the size', () {
      expect(
        () => service.validate(fileName: 'a.pdf', sizeBytes: AvatarService.maxBytes + 1),
        throwsA(isA<AvatarInvalidType>()),
      );
    });
  });

  group('AvatarService.contentTypeFor', () {
    test('maps each allowed extension to its MIME type', () {
      expect(service.contentTypeFor('a.png'), 'image/png');
      expect(service.contentTypeFor('a.jpg'), 'image/jpeg');
      expect(service.contentTypeFor('A.JPEG'), 'image/jpeg');
      expect(service.contentTypeFor('a.webp'), 'image/webp');
      expect(service.contentTypeFor('a.bin'), 'application/octet-stream');
    });
  });
}
