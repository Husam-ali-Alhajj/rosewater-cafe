import 'dart:typed_data';

import 'supabase_client.dart';

/// Thrown by [IdDocumentService.validate] when a file is over the design's
/// stated limit. Carries the limit so the UI can phrase the message without
/// hardcoding the number twice.
class IdDocumentTooLarge implements Exception {
  final int maxBytes;
  const IdDocumentTooLarge(this.maxBytes);
}

/// Thrown by [IdDocumentService.validate] for any extension other than
/// PNG/JPG/PDF — the exact set the design's upload box states.
class IdDocumentInvalidType implements Exception {
  const IdDocumentInvalidType();
}

class IdDocumentService {
  const IdDocumentService();

  static const maxBytes = 10 * 1024 * 1024; // 10MB, per the design's "max 10MB" label
  static const allowedExtensions = {'png', 'jpg', 'jpeg', 'pdf'};

  /// Checked against just the file's name/size — never its bytes — so this
  /// can run (and reject) immediately after picking, before any upload is
  /// even attempted, not after one fails partway through.
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

  /// Uploads to the private `id-documents` bucket at `{user_id}/{filename}`
  /// — that exact path shape is what the storage RLS policies
  /// (initial_schema.sql) check via
  /// `(storage.foldername(name))[1] = auth.uid()::text`, so a mismatched
  /// path would be rejected by RLS rather than land somewhere unreadable.
  ///
  /// `verification_status` is deliberately never sent — the column
  /// defaults to 'pending', and the insert policy's
  /// `with check (... and verification_status = 'pending')` would reject
  /// the row outright if anything else were ever sent, so there's no path
  /// from this client to a non-pending row.
  Future<void> uploadAndRecord({required Uint8List bytes, required String fileName}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    validate(fileName: fileName, sizeBytes: bytes.length);

    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? 'bin' : fileName.substring(dot + 1).toLowerCase();
    final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await supabase.storage.from('id-documents').uploadBinary(storagePath, bytes);

    await supabase.from('id_documents').insert({
      'user_id': userId,
      'storage_path': storagePath,
    });
  }
}
