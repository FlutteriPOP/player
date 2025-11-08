import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Service to generate and manage video thumbnails
class ThumbnailService {
  static const int _thumbnailMaxWidth = 300;
  static const int _thumbnailQuality = 75;

  /// Generate thumbnail from video file
  static Future<String?> generateThumbnail(String videoPath) async {
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        debugPrint('Video file does not exist: $videoPath');
        return null;
      }

      // Use cache directory for thumbnails
      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory(path.join(cacheDir.path, 'thumbnails'));

      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // Generate thumbnail filename based on video path hash
      final videoName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath = path.join(
        thumbnailDir.path,
        '${videoName}_${videoFile.lastModifiedSync().millisecondsSinceEpoch}.png',
      );

      // Check if thumbnail already exists
      final existingThumbnail = File(thumbnailPath);
      if (await existingThumbnail.exists()) {
        return thumbnailPath;
      }

      // Generate new thumbnail
      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailDir.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: _thumbnailMaxWidth,
        quality: _thumbnailQuality,
        timeMs: 1000, // Get thumbnail at 1 second
      );

      return generatedPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Generate thumbnail at specific time position
  static Future<String?> generateThumbnailAtTime(
    String videoPath,
    int timeMs,
  ) async {
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        debugPrint('Video file does not exist: $videoPath');
        return null;
      }

      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory(path.join(cacheDir.path, 'thumbnails'));

      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final videoName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath = path.join(
        thumbnailDir.path,
        '${videoName}_$timeMs.png',
      );

      // Check if thumbnail already exists
      final existingThumbnail = File(thumbnailPath);
      if (await existingThumbnail.exists()) {
        return thumbnailPath;
      }

      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailDir.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: _thumbnailMaxWidth,
        quality: _thumbnailQuality,
        timeMs: timeMs,
      );

      return generatedPath;
    } catch (e) {
      debugPrint('Error generating thumbnail at time: $e');
      return null;
    }
  }

  /// Clear all cached thumbnails
  static Future<void> clearThumbnailCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final thumbnailDir = Directory(path.join(cacheDir.path, 'thumbnails'));

      if (await thumbnailDir.exists()) {
        await thumbnailDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }

  /// Delete thumbnail file
  static Future<void> deleteThumbnail(String? thumbnailPath) async {
    if (thumbnailPath != null) {
      try {
        final file = File(thumbnailPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore errors
      }
    }
  }
}
