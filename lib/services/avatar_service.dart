import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// The photo is bigger than the size limit.
class AvatarTooLarge implements Exception {
  final int maxBytes;
  const AvatarTooLarge(this.maxBytes);
}

/// The photo isn't PNG, JPG or WebP.
class AvatarInvalidType implements Exception {
  const AvatarInvalidType();
}

/// Profile photos, stored in the private `avatars` bucket in a folder named after each user's id.
/// Storage rules stop anyone reaching another user's folder.
class AvatarService {
  const AvatarService();

  static const bucket = 'avatars';
  static const maxBytes = 5 * 1024 * 1024; // 5MB, same as the bucket's limit
  static const allowedExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  /// How long a display link stays valid.
  static const signedUrlLifetime = Duration(hours: 1);

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  /// Only checks the name and size, so a bad photo is rejected right after picking.
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

  /// Uploads to `avatars/<user_id>/<timestamp>.<ext>` and returns that path (saved in
  /// `profiles.avatar_url`). A new name each time avoids showing a cached old photo.
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

  /// A short-lived link for showing the photo, or null if it can't be made.
  Future<String?> signedUrl(String path) async {
    try {
      return await supabase.storage.from(bucket).createSignedUrl(path, signedUrlLifetime.inSeconds);
    } catch (_) {
      return null;
    }
  }

  /// Deletes a replaced photo. Failures are ignored; the new photo is already saved.
  Future<void> deleteQuietly(String path) async {
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (_) {}
  }
}
