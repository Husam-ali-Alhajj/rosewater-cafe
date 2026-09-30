import 'dart:typed_data';

import 'supabase_client.dart';

/// The file is bigger than the design's limit.
class IdDocumentTooLarge implements Exception {
  final int maxBytes;
  const IdDocumentTooLarge(this.maxBytes);
}

/// The file isn't PNG, JPG or PDF.
class IdDocumentInvalidType implements Exception {
  const IdDocumentInvalidType();
}

class IdDocumentService {
  const IdDocumentService();

  static const bucket = 'id-documents';
  static const maxBytes = 10 * 1024 * 1024; // 10MB, as the design says
  static const allowedExtensions = {'png', 'jpg', 'jpeg', 'pdf'};

  /// Only checks the name and size, so a bad file is rejected right after picking.
  void validate({required String fileName, required int sizeBytes}) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw const IdDocumentInvalidType();
    }
    if (sizeBytes > maxBytes) {
      throw const IdDocumentTooLarge(maxBytes);
    }
  }

  String contentTypeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  /// Uploads to the private `id-documents` bucket at `{user_id}/{filename}` (storage rules require
  /// this path) and records it. The status always starts as 'pending'; the database rejects
  /// anything else.
  Future<void> uploadAndRecord({required Uint8List bytes, required String fileName}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    validate(fileName: fileName, sizeBytes: bytes.length);

    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? 'bin' : fileName.substring(dot + 1).toLowerCase();
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage.from(bucket).uploadBinary(storagePath, bytes);

    await supabase.from('id_documents').insert({'user_id': userId, 'storage_path': storagePath});
  }
}
