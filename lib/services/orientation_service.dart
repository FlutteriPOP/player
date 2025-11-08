import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to manage screen orientation changes
class OrientationService {
  /// Enable all orientations (for video player screen)
  static Future<void> enableAllOrientations() async {
    debugPrint('🔄 OrientationService: Enabling all orientations');
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('✅ OrientationService: All orientations enabled successfully');
    } catch (e) {
      debugPrint('❌ OrientationService: Error enabling all orientations: $e');
    }
  }

  /// Force landscape mode (for fullscreen)
  static Future<void> forceLandscape() async {
    debugPrint('🔄 OrientationService: Forcing landscape mode');
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('✅ OrientationService: Landscape mode forced successfully');
    } catch (e) {
      debugPrint('❌ OrientationService: Error forcing landscape: $e');
    }
  }

  /// Force portrait mode (for video player)
  static Future<void> forcePortrait() async {
    debugPrint('🔄 OrientationService: Forcing portrait mode');
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      debugPrint('✅ OrientationService: Portrait mode forced successfully');
    } catch (e) {
      debugPrint('❌ OrientationService: Error forcing portrait: $e');
    }
  }

  /// Lock to portrait mode (for home screen)
  static Future<void> lockPortrait() async {
    debugPrint('🔄 OrientationService: Locking to portrait mode');
    try {
      // First enable all orientations to allow rotation
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      debugPrint('   - Temporarily enabled all orientations');

      // Small delay to allow rotation
      await Future.delayed(const Duration(milliseconds: 100));

      // Then lock to portrait
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      debugPrint('✅ OrientationService: Portrait mode locked successfully');
    } catch (e) {
      debugPrint('❌ OrientationService: Error locking portrait: $e');
    }
  }
}
