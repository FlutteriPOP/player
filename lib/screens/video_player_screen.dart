import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/video_provider.dart';
import '../services/orientation_service.dart';
import '../widgets/custom_video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupScreen();
    });
  }

  Future<void> _setupScreen() async {
    // Enable wakelock to keep screen on during video playback
    await WakelockPlus.enable();

    // Use a small delay to ensure the screen is fully built
    await Future.delayed(const Duration(milliseconds: 100));

    // Enable all orientations so user can rotate freely
    await OrientationService.enableAllOrientations();
  }

  @override
  void dispose() {
    _cleanupScreen();
    super.dispose();
  }

  Future<void> _cleanupScreen() async {
    // Pause video when leaving
    final provider = Provider.of<VideoProvider>(context, listen: false);
    provider.videoPlayerController?.pause();

    // Disable wakelock
    await WakelockPlus.disable();

    // Lock back to portrait when leaving video player
    await OrientationService.lockPortrait();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Pause video when going back
          final provider = Provider.of<VideoProvider>(context, listen: false);
          provider.videoPlayerController?.pause();

          // Cleanup before popping
          await _cleanupScreen();

          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: SizedBox.expand(
          child: Consumer<VideoProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.deepPurpleAccent,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Loading video...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (provider.videoPlayerController == null) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade400,
                          size: 72,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Failed to load video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              provider.errorMessage!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _cleanupScreen();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const CustomVideoPlayer();
            },
          ),
        ),
      ),
    );
  }
}
