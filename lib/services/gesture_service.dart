import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart' as vc;

/// Service for managing device gestures and system controls
class GestureService {
  static final ScreenBrightness _screenBrightness = ScreenBrightness();

  // Volume Control
  /// Get current system volume (0.0 to 1.0)
  static Future<double> getVolume() async {
    try {
      return await vc.VolumeController.instance.getVolume();
    } catch (e) {
      debugPrint('Error getting volume: $e');
      return 0.5;
    }
  }

  /// Set system volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await vc.VolumeController.instance.setVolume(clampedVolume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Increase volume by 10%
  static Future<void> increaseVolume() async {
    try {
      final current = await getVolume();
      await setVolume((current + 0.1).clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error increasing volume: $e');
    }
  }

  /// Decrease volume by 10%
  static Future<void> decreaseVolume() async {
    try {
      final current = await getVolume();
      await setVolume((current - 0.1).clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error decreasing volume: $e');
    }
  }

  /// Mute volume (set to 0)
  static Future<void> muteVolume() async {
    try {
      await setVolume(0.0);
    } catch (e) {
      debugPrint('Error muting volume: $e');
    }
  }

  /// Set volume to maximum
  static Future<void> maxVolume() async {
    try {
      await setVolume(1.0);
    } catch (e) {
      debugPrint('Error setting max volume: $e');
    }
  }

  // Brightness Control
  /// Get current screen brightness (0.0 to 1.0)
  static Future<double> getBrightness() async {
    try {
      return await _screenBrightness.application;
    } catch (e) {
      debugPrint('Error getting brightness: $e');
      return 0.5;
    }
  }

  /// Set screen brightness (0.0 to 1.0)
  static Future<void> setBrightness(double brightness) async {
    try {
      final clampedBrightness = brightness.clamp(0.0, 1.0);
      await _screenBrightness.setApplicationScreenBrightness(clampedBrightness);
    } catch (e) {
      debugPrint('Error setting brightness: $e');
    }
  }

  /// Increase brightness by 10%
  static Future<void> increaseBrightness() async {
    try {
      final current = await getBrightness();
      await setBrightness((current + 0.1).clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error increasing brightness: $e');
    }
  }

  /// Decrease brightness by 10%
  static Future<void> decreaseBrightness() async {
    try {
      final current = await getBrightness();
      await setBrightness((current - 0.1).clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error decreasing brightness: $e');
    }
  }

  /// Reset brightness to system default
  static Future<void> resetBrightness() async {
    try {
      await _screenBrightness.resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Error resetting brightness: $e');
    }
  }
}
