import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/services/app_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A trivial, real [ImageProvider] so a real entry can be put in Flutter's
/// image cache without touching the network or the file system.
class _SolidColorImage extends ImageProvider<_SolidColorImage> {
  const _SolidColorImage(this.id);
  final String id;

  @override
  Future<_SolidColorImage> obtainKey(ImageConfiguration configuration) async => this;

  @override
  ImageStreamCompleter loadImage(_SolidColorImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(_load());
  }

  Future<ImageInfo> _load() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 4), Paint());
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    return ImageInfo(image: image);
  }

  @override
  bool operator ==(Object other) => other is _SolidColorImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = AppSettingsService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  group('AppSettingsService cache', () {
    test('cacheSizeBytes is real: 0 with nothing cached', () {
      expect(service.cacheSizeBytes(), 0);
    });

    test('cacheSizeBytes reflects what is actually in Flutter\'s image cache', () async {
      final stream = const _SolidColorImage('a').resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      stream.addListener(ImageStreamListener((info, sync) => completer.complete()));
      await completer.future;

      expect(service.cacheSizeBytes(), greaterThan(0));
    });

    test('clearImageCache empties it for real', () async {
      final stream = const _SolidColorImage('b').resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      stream.addListener(ImageStreamListener((info, sync) => completer.complete()));
      await completer.future;
      expect(service.cacheSizeBytes(), greaterThan(0));

      service.clearImageCache();

      expect(service.cacheSizeBytes(), 0);
      expect(PaintingBinding.instance.imageCache.liveImageCount, 0);
    });
  });

  group('AppSettingsService.clearLocalPreferences', () {
    test('wipes every locally saved preference', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setBool('notification_settings.u1.sms', true);
      expect(prefs.getKeys(), isNotEmpty);

      await service.clearLocalPreferences();

      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
  });
}
