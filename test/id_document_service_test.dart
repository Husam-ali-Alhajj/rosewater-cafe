import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/id_document_service.dart';

// Exercises IdDocumentService.validate() directly (name + size only, no
// actual file bytes or network) since it must reject before any upload is
// attempted — this is the fastest, least flaky way to prove that boundary,
// without fighting a browser's native file-picker dialog.
void main() {
  const service = IdDocumentService();

  group('validate', () {
    test('accepts a PNG under the size limit', () {
      expect(
        () => service.validate(fileName: 'license.png', sizeBytes: 1024),
        returnsNormally,
      );
    });

    test('accepts a JPG under the size limit', () {
      expect(
        () => service.validate(fileName: 'license.jpg', sizeBytes: 1024),
        returnsNormally,
      );
    });

    test('accepts a PDF under the size limit', () {
      expect(
        () => service.validate(fileName: 'license.pdf', sizeBytes: 1024),
        returnsNormally,
      );
    });

    test('accepts a file exactly at the size limit', () {
      expect(
        () => service.validate(fileName: 'license.png', sizeBytes: IdDocumentService.maxBytes),
        returnsNormally,
      );
    });

    test('rejects a file one byte over the size limit', () {
      expect(
        () => service.validate(fileName: 'license.png', sizeBytes: IdDocumentService.maxBytes + 1),
        throwsA(isA<IdDocumentTooLarge>()),
      );
    });

    test('rejects a disallowed extension (e.g. a HEIC photo)', () {
      expect(
        () => service.validate(fileName: 'license.heic', sizeBytes: 1024),
        throwsA(isA<IdDocumentInvalidType>()),
      );
    });

    test('rejects a file with no extension at all', () {
      expect(
        () => service.validate(fileName: 'license', sizeBytes: 1024),
        throwsA(isA<IdDocumentInvalidType>()),
      );
    });

    test('extension check is case-insensitive', () {
      expect(
        () => service.validate(fileName: 'LICENSE.PNG', sizeBytes: 1024),
        returnsNormally,
      );
    });
  });
}
