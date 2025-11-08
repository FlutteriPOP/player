import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/video_model.dart';
import '../services/thumbnail_service.dart';
import '../services/video_history_service.dart';

/// Provider for managing video player state and operations
class VideoProvider extends ChangeNotifier {
  VideoPlayerController? _videoPlayerController;
  String? _currentVideoPath;
  bool _isLoading = false;
  String? _errorMessage;
  VideoModel? _currentVideo;
  Timer? _positionSaverTimer;

  VideoPlayerController? get videoPlayerController => _videoPlayerController;
  String? get currentVideoPath => _currentVideoPath;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VideoModel? get currentVideo => _currentVideo;
  bool get hasVideo => _videoPlayerController != null;
  bool get isPlaying => _videoPlayerController?.value.isPlaying ?? false;
  Duration get position =>
      _videoPlayerController?.value.position ?? Duration.zero;
  Duration get duration =>
      _videoPlayerController?.value.duration ?? Duration.zero;

  /// Load a video from file path
  Future<bool> loadVideo(String path) async {
    try {
      // Validate file exists
      final file = File(path);
      if (!await file.exists()) {
        _setError('Video file not found: $path');
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Dispose previous controller
      await disposeControllers();

      // Load existing video data or create new
      _currentVideo = await VideoHistoryService.getVideo(path);
      _currentVideo ??= await VideoModel.fromFile(file);

      // Initialize video player
      _videoPlayerController = VideoPlayerController.file(file);

      try {
        await _videoPlayerController!.initialize();
      } catch (e) {
        _setError('Failed to initialize video: ${e.toString()}');
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;
        return false;
      }

      // Validate video is playable
      if (!_videoPlayerController!.value.isInitialized) {
        _setError('Video failed to initialize');
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;
        return false;
      }

      // Update video duration
      final duration = _videoPlayerController!.value.duration;
      if (duration.inMilliseconds > 0) {
        _currentVideo = _currentVideo!.copyWith(duration: duration);
      }

      // Generate thumbnail if not exists (async, don't wait)
      if (_currentVideo!.thumbnailPath == null) {
        ThumbnailService.generateThumbnail(path)
            .then((thumbnailPath) {
              if (thumbnailPath != null && _currentVideo != null) {
                _currentVideo = _currentVideo!.copyWith(
                  thumbnailPath: thumbnailPath,
                );
                VideoHistoryService.updateVideo(_currentVideo!);
              }
            })
            .catchError((e) {
              // Silently fail thumbnail generation
              debugPrint('Thumbnail generation failed: $e');
            });
      }

      // Enable wakelock
      try {
        await WakelockPlus.enable();
      } catch (e) {
        debugPrint('Failed to enable wakelock: $e');
      }

      // Restore last position if available
      if (_currentVideo!.lastPosition != null &&
          _currentVideo!.lastPosition!.inSeconds > 5 &&
          _currentVideo!.lastPosition! < duration) {
        try {
          await _videoPlayerController!.seekTo(_currentVideo!.lastPosition!);
        } catch (e) {
          debugPrint('Failed to restore position: $e');
        }
      }

      // Auto play
      try {
        await _videoPlayerController!.play();
      } catch (e) {
        debugPrint('Auto-play failed: $e');
      }

      // Increment play count
      await VideoHistoryService.incrementPlayCount(path);

      // Save to history
      await VideoHistoryService.saveToHistory(_currentVideo!);

      _currentVideoPath = path;
      _isLoading = false;
      notifyListeners();

      // Listen to video player state changes
      _videoPlayerController!.addListener(() {
        notifyListeners();
      });

      // Start periodic position saving
      _startPositionSaver();

      return true;
    } catch (e, stackTrace) {
      debugPrint('Error loading video: $e');
      debugPrint('Stack trace: $stackTrace');
      _setError('Failed to load video: ${e.toString()}');
      return false;
    }
  }

  /// Start periodic position saving
  void _startPositionSaver() {
    _positionSaverTimer?.cancel();
    _positionSaverTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_videoPlayerController != null &&
          _currentVideoPath != null &&
          _videoPlayerController!.value.isInitialized) {
        final position = _videoPlayerController!.value.position;
        final duration = _videoPlayerController!.value.duration;

        // Only save if position is valid and video is playing
        if (position.inMilliseconds > 0 &&
            duration.inMilliseconds > 0 &&
            position < duration) {
          VideoHistoryService.savePosition(_currentVideoPath!, position);
        }
      }
    });
  }

  /// Set error state
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Play video
  Future<void> play() async {
    try {
      await _videoPlayerController?.play();
      notifyListeners();
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  /// Pause video
  Future<void> pause() async {
    try {
      await _videoPlayerController?.pause();
      notifyListeners();
    } catch (e) {
      debugPrint('Pause error: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _videoPlayerController?.seekTo(position);
      notifyListeners();
    } catch (e) {
      debugPrint('Seek error: $e');
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _videoPlayerController?.setPlaybackSpeed(speed);
      notifyListeners();
    } catch (e) {
      debugPrint('Set playback speed error: $e');
    }
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _videoPlayerController?.setVolume(volume.clamp(0.0, 1.0));
      notifyListeners();
    } catch (e) {
      debugPrint('Set volume error: $e');
    }
  }

  /// Dispose controllers and cleanup
  Future<void> disposeControllers() async {
    // Cancel position saver
    _positionSaverTimer?.cancel();
    _positionSaverTimer = null;

    // Remove listener
    _videoPlayerController?.removeListener(() {});

    // Save final position before disposing
    if (_videoPlayerController != null &&
        _currentVideoPath != null &&
        _videoPlayerController!.value.isInitialized) {
      try {
        final position = _videoPlayerController!.value.position;
        final duration = _videoPlayerController!.value.duration;
        if (position.inMilliseconds > 0 &&
            duration.inMilliseconds > 0 &&
            position < duration) {
          await VideoHistoryService.savePosition(_currentVideoPath!, position);
        }
      } catch (e) {
        debugPrint('Error saving final position: $e');
      }
    }

    // Dispose controller
    try {
      await _videoPlayerController?.dispose();
    } catch (e) {
      debugPrint('Error disposing controller: $e');
    }

    _videoPlayerController = null;
    _currentVideoPath = null;
    _currentVideo = null;

    // Disable wakelock
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Failed to disable wakelock: $e');
    }

    notifyListeners();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }
}
