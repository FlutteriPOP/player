import 'dart:io';

/// Model class for video metadata
class VideoModel {
  final String path;
  final String name;
  final int? fileSize;
  final DateTime? lastModified;
  final DateTime? lastPlayed;
  final Duration? duration;
  final String? thumbnailPath;
  final int playCount;
  final Duration? lastPosition;

  VideoModel({
    required this.path,
    required this.name,
    this.fileSize,
    this.lastModified,
    this.lastPlayed,
    this.duration,
    this.thumbnailPath,
    this.playCount = 0,
    this.lastPosition,
  }) {
    // Validate path is not empty
    if (path.isEmpty) {
      throw ArgumentError('Video path cannot be empty');
    }
    // Validate name is not empty
    if (name.isEmpty) {
      throw ArgumentError('Video name cannot be empty');
    }
    // Validate playCount is non-negative
    if (playCount < 0) {
      throw ArgumentError('Play count cannot be negative');
    }
  }

  /// Create VideoModel from file path
  static Future<VideoModel> fromFile(File file) async {
    final stat = await file.stat();
    return VideoModel(
      path: file.path,
      name: file.path.split('/').last,
      fileSize: stat.size,
      lastModified: stat.modified,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'fileSize': fileSize,
      'lastModified': lastModified?.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'thumbnailPath': thumbnailPath,
      'playCount': playCount,
      'lastPosition': lastPosition?.inMilliseconds,
    };
  }

  /// Create from JSON
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    try {
      return VideoModel(
        path: json['path'] as String? ?? '',
        name: json['name'] as String? ?? '',
        fileSize: json['fileSize'] as int?,
        lastModified: json['lastModified'] != null
            ? DateTime.tryParse(json['lastModified'] as String)
            : null,
        lastPlayed: json['lastPlayed'] != null
            ? DateTime.tryParse(json['lastPlayed'] as String)
            : null,
        duration: json['duration'] != null
            ? Duration(milliseconds: json['duration'] as int)
            : null,
        thumbnailPath: json['thumbnailPath'] as String?,
        playCount: (json['playCount'] as int?) ?? 0,
        lastPosition: json['lastPosition'] != null
            ? Duration(milliseconds: json['lastPosition'] as int)
            : null,
      );
    } catch (e) {
      throw FormatException('Invalid video model JSON: $e');
    }
  }

  /// Copy with new values
  VideoModel copyWith({
    String? path,
    String? name,
    int? fileSize,
    DateTime? lastModified,
    DateTime? lastPlayed,
    Duration? duration,
    String? thumbnailPath,
    int? playCount,
    Duration? lastPosition,
  }) {
    return VideoModel(
      path: path ?? this.path,
      name: name ?? this.name,
      fileSize: fileSize ?? this.fileSize,
      lastModified: lastModified ?? this.lastModified,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      playCount: playCount ?? this.playCount,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }

  /// Check if file exists
  Future<bool> exists() async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file extension
  String get extension {
    return path.split('.').last.toUpperCase();
  }

  /// Check if video was recently played (within 24 hours)
  bool get isRecentlyPlayed {
    if (lastPlayed == null) return false;
    final difference = DateTime.now().difference(lastPlayed!);
    return difference.inHours < 24;
  }

  /// Get watch progress percentage
  double get watchProgress {
    if (duration == null || lastPosition == null) return 0.0;
    if (duration!.inMilliseconds == 0) return 0.0;
    return (lastPosition!.inMilliseconds / duration!.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  /// Check if video is partially watched
  bool get isPartiallyWatched {
    final progress = watchProgress;
    return progress > 0.05 && progress < 0.95;
  }

  /// Check if video is fully watched
  bool get isFullyWatched {
    return watchProgress >= 0.95;
  }
}
