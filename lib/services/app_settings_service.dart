import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backs App Settings' "Data & Storage" section. The only thing cached is the profile photo.
class AppSettingsService {
  const AppSettingsService();

  /// Real size of Flutter's image cache in bytes.
  int cacheSizeBytes() => PaintingBinding.instance.imageCache.currentSizeBytes;

  /// Empties the image cache.
  void clearImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
  }

  /// Clears every local setting (for example, the onboarding flag). Doesn't touch the login
  /// session; the caller signs out afterwards.
  Future<void> clearLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
