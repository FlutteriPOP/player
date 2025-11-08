import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FilePickerService {
  static Future<String?> pickVideo(BuildContext context) async {
    try {
      // Request storage permission
      final status = await _requestPermission();

      if (!status.isGranted) {
        if (context.mounted) {
          _showPermissionDeniedDialog(context);
        }
        return null;
      }

      // Pick video file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return result.files.single.path!;
      }

      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  static Future<PermissionStatus> _requestPermission() async {
    if (await Permission.videos.isGranted) {
      return PermissionStatus.granted;
    }

    if (await Permission.storage.isGranted) {
      return PermissionStatus.granted;
    }

    // Try videos permission first (Android 13+)
    var status = await Permission.videos.request();
    if (status.isGranted) {
      return status;
    }

    // Fallback to storage permission
    status = await Permission.storage.request();
    return status;
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Permission Required', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Storage permission is required to access videos. Please grant permission in settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
