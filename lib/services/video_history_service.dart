import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video_model.dart';

/// Service to manage video history and metadata
class VideoHistoryService {
  static const String _historyKey = 'video_history';
  static const int _maxHistoryItems = 50;

  /// Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  /// Save video to history
  static Future<void> saveToHistory(VideoModel video) async {
    try {
      final prefs = await _prefs;
      final history = await getHistory();

      // Remove existing entry if present
      history.removeWhere((v) => v.path == video.path);

      // Add to beginning
      history.insert(0, video);

      // Limit history size
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save to preferences
      final jsonList = history.map((v) => v.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving to history: $e');
      rethrow;
    }
  }

  /// Get video history
  static Future<List<VideoModel>> getHistory() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(_historyKey);

      if (jsonString == null || jsonString.isEmpty) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) {
            try {
              return VideoModel.fromJson(json);
            } catch (e) {
              debugPrint('Error parsing video model: $e');
              return null;
            }
          })
          .whereType<VideoModel>()
          .toList();
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  /// Get recent videos (last 10)
  static Future<List<VideoModel>> getRecentVideos() async {
    final history = await getHistory();
    return history.take(10).toList();
  }

  /// Update video metadata
  static Future<void> updateVideo(VideoModel video) async {
    try {
      final history = await getHistory();
      final index = history.indexWhere((v) => v.path == video.path);

      if (index != -1) {
        history[index] = video;
        final prefs = await _prefs;
        final jsonList = history.map((v) => v.toJson()).toList();
        await prefs.setString(_historyKey, jsonEncode(jsonList));
      }
    } catch (e) {
      debugPrint('Error updating video: $e');
      rethrow;
    }
  }

  /// Remove video from history
  static Future<void> removeFromHistory(String videoPath) async {
    try {
      final prefs = await _prefs;
      final history = await getHistory();

      history.removeWhere((v) => v.path == videoPath);

      final jsonList = history.map((v) => v.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error removing from history: $e');
      rethrow;
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Error clearing history: $e');
      rethrow;
    }
  }

  /// Get video by path
  static Future<VideoModel?> getVideo(String path) async {
    final history = await getHistory();
    try {
      return history.firstWhere((v) => v.path == path);
    } catch (e) {
      return null;
    }
  }

  /// Increment play count
  static Future<void> incrementPlayCount(String videoPath) async {
    final video = await getVideo(videoPath);
    if (video != null) {
      final updated = video.copyWith(
        playCount: video.playCount + 1,
        lastPlayed: DateTime.now(),
      );
      await updateVideo(updated);
    }
  }

  /// Save playback position
  static Future<void> savePosition(String videoPath, Duration position) async {
    final video = await getVideo(videoPath);
    if (video != null) {
      final updated = video.copyWith(lastPosition: position);
      await updateVideo(updated);
    }
  }

  /// Get most played videos
  static Future<List<VideoModel>> getMostPlayed({int limit = 10}) async {
    final history = await getHistory();
    history.sort((a, b) => b.playCount.compareTo(a.playCount));
    return history.take(limit).toList();
  }

  /// Get videos by date range
  static Future<List<VideoModel>> getVideosByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final history = await getHistory();
    return history.where((v) {
      if (v.lastPlayed == null) return false;
      return v.lastPlayed!.isAfter(start) && v.lastPlayed!.isBefore(end);
    }).toList();
  }

  /// Get total watch time
  static Future<Duration> getTotalWatchTime() async {
    final history = await getHistory();
    int totalMs = 0;
    for (final video in history) {
      if (video.duration != null) {
        totalMs += video.duration!.inMilliseconds * video.playCount;
      }
    }
    return Duration(milliseconds: totalMs);
  }

  /// Get statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final history = await getHistory();
    int totalVideos = history.length;
    int totalPlays = history.fold(0, (sum, v) => sum + v.playCount);
    final totalTime = await getTotalWatchTime();

    return {
      'totalVideos': totalVideos,
      'totalPlays': totalPlays,
      'totalWatchTime': totalTime,
      'averagePlaysPerVideo': totalVideos > 0 ? totalPlays / totalVideos : 0,
    };
  }
}
