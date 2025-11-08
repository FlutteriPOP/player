import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/video_model.dart';

/// Service to scan for video files on device storage
class VideoScannerService {
  // Supported video file extensions
  static const List<String> _videoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'flv',
    'wmv',
    'webm',
    'm4v',
    '3gp',
    'ts',
    'mts',
    'm2ts',
  ];

  /// Scan for videos in common directories
  static Future<List<VideoModel>> scanForVideos({
    bool includeSubdirectories = true,
    int maxDepth = 5,
  }) async {
    try {
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage permission denied');
        return [];
      }

      final List<VideoModel> videos = [];
      final Set<String> scannedPaths = {}; // To avoid duplicates

      // Get common video directories
      final directories = await _getVideoDirectories();

      for (final directory in directories) {
        if (await directory.exists()) {
          try {
            final foundVideos = await _scanDirectory(
              directory,
              includeSubdirectories: includeSubdirectories,
              maxDepth: maxDepth,
              scannedPaths: scannedPaths,
            );
            videos.addAll(foundVideos);
          } catch (e) {
            debugPrint('Error scanning directory ${directory.path}: $e');
          }
        }
      }

      // Sort by last modified date (newest first)
      videos.sort((a, b) {
        final aDate = a.lastModified ?? DateTime(1970);
        final bDate = b.lastModified ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return videos;
    } catch (e) {
      debugPrint('Error scanning for videos: $e');
      return [];
    }
  }

  /// Get common video directories
  static Future<List<Directory>> _getVideoDirectories() async {
    final List<Directory> directories = [];

    try {
      // Internal storage directories
      if (Platform.isAndroid) {
        // Android common directories
        final externalStorage = await getExternalStorageDirectory();
        if (externalStorage != null) {
          final parent = externalStorage.parent;

          // Common Android video directories
          directories.addAll([
            Directory(path.join(parent.path, 'DCIM', 'Camera')),
            Directory(path.join(parent.path, 'DCIM')),
            Directory(path.join(parent.path, 'Movies')),
            Directory(path.join(parent.path, 'Download')),
            Directory(path.join(parent.path, 'Downloads')),
            Directory(path.join(parent.path, 'Videos')),
            Directory(path.join(parent.path, 'Video')),
            Directory(path.join(parent.path, 'Pictures')),
            Directory(
              path.join(parent.path, 'WhatsApp', 'Media', 'WhatsApp Video'),
            ),
            Directory(path.join(parent.path, 'WhatsApp', 'Media', 'Sent')),
          ]);

          // Try to get external storage (SD card)
          try {
            final externalStorages = await _getExternalStorageDirectories();
            for (final storage in externalStorages) {
              if (await storage.exists()) {
                directories.addAll([
                  Directory(path.join(storage.path, 'DCIM', 'Camera')),
                  Directory(path.join(storage.path, 'DCIM')),
                  Directory(path.join(storage.path, 'Movies')),
                  Directory(path.join(storage.path, 'Download')),
                  Directory(path.join(storage.path, 'Downloads')),
                  Directory(path.join(storage.path, 'Videos')),
                ]);
              }
            }
          } catch (e) {
            debugPrint('Error getting external storage: $e');
          }
        }

        // Try /storage paths for SD card (with permission check)
        try {
          if (await Permission.manageExternalStorage.isGranted) {
            final storageDir = Directory('/storage');
            if (await storageDir.exists()) {
              await for (final entity in storageDir.list()) {
                if (entity is Directory) {
                  final dirName = path.basename(entity.path);
                  // Skip emulated and self directories
                  if (dirName != 'emulated' && dirName != 'self') {
                    directories.addAll([
                      Directory(path.join(entity.path, 'DCIM', 'Camera')),
                      Directory(path.join(entity.path, 'DCIM')),
                      Directory(path.join(entity.path, 'Movies')),
                      Directory(path.join(entity.path, 'Download')),
                      Directory(path.join(entity.path, 'Videos')),
                    ]);
                  }
                }
              }
            }
          }
        } catch (e) {
          // Silently ignore permission errors for /storage
          debugPrint('Skipping /storage scan: limited permissions');
        }
      } else if (Platform.isIOS) {
        // iOS directories
        final appDocDir = await getApplicationDocumentsDirectory();
        directories.addAll([
          Directory(path.join(appDocDir.path, '..', 'DCIM')),
          Directory(path.join(appDocDir.path, '..', 'Movies')),
        ]);
      }
    } catch (e) {
      debugPrint('Error getting video directories: $e');
    }

    return directories;
  }

  /// Get external storage directories (SD cards)
  static Future<List<Directory>> _getExternalStorageDirectories() async {
    final List<Directory> storages = [];

    try {
      if (Platform.isAndroid) {
        // Only try to access external storage if we have proper permissions
        final hasManagePermission =
            await Permission.manageExternalStorage.isGranted;

        if (hasManagePermission) {
          // Try common external storage paths
          final possiblePaths = [
            '/storage/sdcard1',
            '/storage/extSdCard',
            '/storage/external_SD',
            '/storage/removable/sdcard1',
          ];

          for (final storagePath in possiblePaths) {
            try {
              final dir = Directory(storagePath);
              if (await dir.exists()) {
                storages.add(dir);
              }
            } catch (e) {
              // Skip paths we can't access
              continue;
            }
          }

          // Also check /storage for mounted SD cards
          try {
            final storageDir = Directory('/storage');
            if (await storageDir.exists()) {
              await for (final entity in storageDir.list()) {
                if (entity is Directory) {
                  final dirName = path.basename(entity.path);
                  if (dirName != 'emulated' &&
                      dirName != 'self' &&
                      !dirName.startsWith('sdcard')) {
                    storages.add(entity);
                  }
                }
              }
            }
          } catch (e) {
            // Silently skip if we can't list /storage
            debugPrint('Skipping /storage listing: limited permissions');
          }
        }
      }
    } catch (e) {
      // Silently handle permission errors
      debugPrint('Skipping external storage scan: limited permissions');
    }

    return storages;
  }

  /// Scan a directory for video files
  static Future<List<VideoModel>> _scanDirectory(
    Directory directory, {
    required bool includeSubdirectories,
    required int maxDepth,
    required Set<String> scannedPaths,
    int currentDepth = 0,
  }) async {
    final List<VideoModel> videos = [];

    if (currentDepth > maxDepth) {
      return videos;
    }

    try {
      if (!await directory.exists()) {
        return videos;
      }

      await for (final entity in directory.list()) {
        try {
          if (entity is File) {
            final extension = path
                .extension(entity.path)
                .toLowerCase()
                .replaceFirst('.', '');

            if (_videoExtensions.contains(extension)) {
              final filePath = entity.path;

              // Skip if already scanned
              if (scannedPaths.contains(filePath)) {
                continue;
              }

              scannedPaths.add(filePath);

              try {
                final video = await VideoModel.fromFile(entity);
                videos.add(video);
              } catch (e) {
                debugPrint('Error creating video model for ${entity.path}: $e');
              }
            }
          } else if (entity is Directory && includeSubdirectories) {
            // Recursively scan subdirectories
            final subVideos = await _scanDirectory(
              entity,
              includeSubdirectories: includeSubdirectories,
              maxDepth: maxDepth,
              scannedPaths: scannedPaths,
              currentDepth: currentDepth + 1,
            );
            videos.addAll(subVideos);
          }
        } catch (e) {
          // Skip files/directories that can't be accessed
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${directory.path}: $e');
    }

    return videos;
  }

  /// Request storage permission
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use media permissions
      if (await Permission.videos.isGranted ||
          await Permission.photos.isGranted ||
          await Permission.audio.isGranted) {
        return true;
      }

      // Try videos permission first (Android 13+)
      var status = await Permission.videos.request();
      if (status.isGranted) {
        return true;
      }

      // Try photos permission
      status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback to storage permission (Android 12 and below)
      if (await Permission.storage.isGranted) {
        return true;
      }

      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // If basic permissions granted but limited, still allow scanning
      // (scoped storage will limit access to media files only)
      if (status.isLimited) {
        return true;
      }

      return false;
    } else if (Platform.isIOS) {
      // iOS uses photo library permission
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }

    return true; // For other platforms, assume permission granted
  }

  /// Get video count in a directory (quick check)
  static Future<int> getVideoCount(Directory directory) async {
    int count = 0;
    try {
      if (!await directory.exists()) {
        return 0;
      }

      await for (final entity in directory.list()) {
        if (entity is File) {
          final extension = path
              .extension(entity.path)
              .toLowerCase()
              .replaceFirst('.', '');
          if (_videoExtensions.contains(extension)) {
            count++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error counting videos: $e');
    }
    return count;
  }
}
