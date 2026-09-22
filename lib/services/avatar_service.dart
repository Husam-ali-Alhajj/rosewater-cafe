import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// Thrown by [AvatarService.validate] when a photo is over the size limit.
/// Carries the limit so the UI can phrase the message without hardcoding
/// the number twice.
class AvatarTooLarge implements Exception {
  final int maxBytes;
  const AvatarTooLarge(this.maxBytes);
}

/// Thrown by [AvatarService.validate] for any extension other than
/// PNG/JPG/WebP.
class AvatarInvalidType implements Exception {
  const AvatarInvalidType();
}

/// Profile-photo storage, the same pattern as [IdDocumentService] (decision
/// #18): a private bucket -- `avatars` -- where each user's files live in a
/// folder named for their own user id, enforced by storage RLS
/// (`(storage.foldername(name))[1] = auth.uid()::text`). Nobody can read,
/// write, or delete another user's folder.
class AvatarService {
  const AvatarService();

  static const bucket = 'avatars';
  static const maxBytes = 5 * 1024 * 1024; // 5MB (also the bucket's own limit)
  static const allowedExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  /// How long a signed display URL stays valid.
  static const signedUrlLifetime = Duration(hours: 1);

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  /// Checked against just the file's name/size -- never its bytes -- so this
  /// can run (and reject) immediately after picking, before any upload.
  void validate({required String fileName, required int sizeBytes}) {
    if (!allowedExtensions.contains(_extensionOf(fileName))) {
      throw const AvatarInvalidType();
    }
    if (sizeBytes > maxBytes) {
      throw const AvatarTooLarge(maxBytes);
    }
  }

  String contentTypeFor(String fileName) {
    return switch (_extensionOf(fileName)) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }

  /// Uploads to `avatars/<user_id>/<timestamp>.<ext>` and returns that
  /// storage path (what gets saved in `profiles.avatar_url`). The path must
  /// start with the caller's own user id or storage RLS rejects it. A fresh
  /// name each time (rather than overwriting one fixed file) means a new
  /// photo is never masked by a cached copy of the old one.
  Future<String> upload({required Uint8List bytes, required String fileName}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    validate(fileName: fileName, sizeBytes: bytes.length);

    final ext = _extensionOf(fileName);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentTypeFor(fileName)));
    return path;
  }

  /// A short-lived signed URL for displaying [path], or null if it can't be
  /// made (missing file, or a path outside the caller's own folder, which
  /// storage RLS refuses).
  Future<String?> signedUrl(String path) async {
    try {
      return await supabase.storage.from(bucket).createSignedUrl(path, signedUrlLifetime.inSeconds);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort removal of a replaced photo so old files don't pile up. A
  /// failure is ignored on purpose: the new photo is already saved, and a
  /// leftover file is harmless.
  Future<void> deleteQuietly(String path) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (_) {}
  }
}
