import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/id_document_service.dart';

// Tests IdDocumentService.validate() directly: it only needs a name and size, and must reject bad
// files before any upload.
void main() {
  const service = IdDocumentService();

  group('validate', () {
    test('accepts a PNG under the size limit', () {
      expect(() => service.validate(fileName: 'license.png', sizeBytes: 1024), returnsNormally);
    });

    test('accepts a JPG under the size limit', () {
      expect(() => service.validate(fileName: 'license.jpg', sizeBytes: 1024), returnsNormally);
    });

    test('accepts a PDF under the size limit', () {
      expect(() => service.validate(fileName: 'license.pdf', sizeBytes: 1024), returnsNormally);
    });

    test('accepts a file exactly at the size limit', () {
      expect(() => service.validate(fileName: 'license.png', sizeBytes: IdDocumentService.maxBytes), returnsNormally);
    });

    test('rejects a file one byte over the size limit', () {
      expect(
        () => service.validate(fileName: 'license.png', sizeBytes: IdDocumentService.maxBytes + 1),
        throwsA(isA<IdDocumentTooLarge>()),
      );
    });

    test('rejects a disallowed extension (e.g. a HEIC photo)', () {
      expect(() => service.validate(fileName: 'license.heic', sizeBytes: 1024), throwsA(isA<IdDocumentInvalidType>()));
    });

    test('rejects a file with no extension at all', () {
      expect(() => service.validate(fileName: 'license', sizeBytes: 1024), throwsA(isA<IdDocumentInvalidType>()));
    });

    test('extension check is case-insensitive', () {
      expect(() => service.validate(fileName: 'LICENSE.PNG', sizeBytes: 1024), returnsNormally);
    });
  });
}
