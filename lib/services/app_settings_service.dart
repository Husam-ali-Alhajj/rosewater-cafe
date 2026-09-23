import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backs the App Settings screen's "Data & Storage" section. Deliberately
/// small: this app has almost nothing to manage locally (no big asset/network
/// image caching -- the one real user of Flutter's image cache is the
/// profile photo's signed URL, `ProfileAvatar`/`Image.network`), so this
/// stays honest about that rather than inventing a bigger cache-management
/// feature than the app actually has (decision #47).
class AppSettingsService {
  const AppSettingsService();

  /// Bytes currently held by Flutter's image cache -- real, computed from
  /// `PaintingBinding.instance.imageCache`, never a fabricated number (the
  /// design's mock shows a static "12.5 MB"; this app has nothing close to
  /// that much cached, so a plausible-looking made-up figure would be exactly
  /// the kind of invented data this project avoids -- see decisions #32/#46).
  int cacheSizeBytes() => PaintingBinding.instance.imageCache.currentSizeBytes;

  /// Drops every cached image (e.g. the profile photo) so the next screen
  /// that needs one re-fetches it.
  void clearImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }

  /// Wipes every local preference this app stores with `shared_preferences`
  /// -- the "has seen onboarding" flag and any saved notification settings.
  /// Does **not** touch the signed-in session (that lives in
  /// `flutter_secure_storage`, a separate store) -- the caller is
  /// responsible for signing out afterwards, since that also has to update
  /// navigation, not just storage.
  Future<void> clearLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
