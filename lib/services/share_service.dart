// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../models/video_model.dart';

/// Service for sharing videos and content
class ShareService {
  /// Share a video file
  Future<void> shareVideo(VideoModel video) async {
    try {
      final file = File(video.path);
      if (!await file.exists()) {
        throw Exception('Video file not found');
      }

      final xFile = XFile(video.path, name: video.name);
      await Share.shareXFiles(
        [xFile],
        text: 'Check out this video: ${video.name}',
        subject: video.name,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Share video path as text
  Future<void> shareVideoPath(VideoModel video) async {
    try {
      await Share.share(
        'Video: ${video.name}\nPath: ${video.path}',
        subject: video.name,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Share multiple videos
  Future<void> shareVideos(List<VideoModel> videos) async {
    try {
      final xFiles = <XFile>[];
      
      for (final video in videos) {
        final file = File(video.path);
        if (await file.exists()) {
          xFiles.add(XFile(video.path, name: video.name));
        }
      }

      if (xFiles.isEmpty) {
        throw Exception('No valid video files to share');
      }

      await Share.shareXFiles(
        xFiles,
        text: 'Sharing ${xFiles.length} video(s)',
      );
    } catch (e) {
      rethrow;
    }
  }
}

