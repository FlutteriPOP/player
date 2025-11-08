import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/video_provider.dart';
import '../services/gesture_service.dart';
import '../services/orientation_service.dart';
import 'video_controls_overlay.dart';

class CustomVideoPlayer extends StatefulWidget {
  const CustomVideoPlayer({super.key});

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  bool _showControls = true;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  Orientation? _currentOrientation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGestures();
  }

  Future<void> _initializeGestures() async {
    _currentVolume = await GestureService.getVolume();
    _currentBrightness = await GestureService.getBrightness();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // Auto-hide controls after 3 seconds
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  Future<void> _rotateVideo() async {
    // Get current orientation from MediaQuery to ensure accuracy
    final currentOrientation = MediaQuery.of(context).orientation;
    final isCurrentlyLandscape = currentOrientation == Orientation.landscape;

    log('🔄 CustomVideoPlayer: Rotate button pressed');
    log('   - Current orientation from MediaQuery: $currentOrientation');
    log('   - _currentOrientation state: $_currentOrientation');
    log('   - isCurrentlyLandscape: $isCurrentlyLandscape');

    if (isCurrentlyLandscape) {
      // Currently landscape - rotate to portrait
      log('   - Action: Rotating to portrait');
      await OrientationService.forcePortrait();
    } else {
      // Currently portrait - rotate to landscape
      log('   - Action: Rotating to landscape');
      await OrientationService.forceLandscape();
    }

    // The OrientationBuilder will update _currentOrientation automatically
    // when the orientation actually changes
  }

  bool get _isLandscape => _currentOrientation == Orientation.landscape;

  void _handleVerticalDrag(DragUpdateDetails details, bool isLeftSide) async {
    final delta = details.delta.dy;

    if (isLeftSide) {
      // Left side - Brightness control
      final change = -delta / 500;
      _currentBrightness = (_currentBrightness + change).clamp(0.0, 1.0);
      await GestureService.setBrightness(_currentBrightness);

      setState(() {
        _showBrightnessIndicator = true;
        _showVolumeIndicator = false;
      });

      _hideIndicators();
    } else {
      // Right side - Volume control
      final change = -delta / 500;
      _currentVolume = (_currentVolume + change).clamp(0.0, 1.0);
      await GestureService.setVolume(_currentVolume);

      setState(() {
        _showVolumeIndicator = true;
        _showBrightnessIndicator = false;
      });

      _hideIndicators();
    }
  }

  void _hideIndicators() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  void _handleDoubleTap(TapDownDetails details, Size size) {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    final controller = provider.videoPlayerController;

    if (controller == null || !controller.value.isInitialized) return;

    final position = details.localPosition.dx;
    final isLeftSide = position < size.width / 2;

    if (isLeftSide) {
      // Double tap left - Rewind 10 seconds
      final currentPosition = controller.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      provider.seekTo(
        newPosition > Duration.zero ? newPosition : Duration.zero,
      );
    } else {
      // Double tap right - Forward 10 seconds
      final currentPosition = controller.value.position;
      final duration = controller.value.duration;
      final newPosition = currentPosition + const Duration(seconds: 10);
      provider.seekTo(newPosition < duration ? newPosition : duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        if (provider.videoPlayerController == null || !_isInitialized) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            ),
          );
        }

        return OrientationBuilder(
          builder: (context, orientation) {
            // Update orientation state immediately
            if (_currentOrientation != orientation) {
              log('📱 OrientationBuilder: Orientation changed');
              log('   - Old: $_currentOrientation');
              log('   - New: $orientation');
              _currentOrientation = orientation;
            }

            final controller = provider.videoPlayerController!;
            final aspectRatio = controller.value.aspectRatio;
            final screenSize = MediaQuery.of(context).size;
            final isLandscape = orientation == Orientation.landscape;

            log('📐 Building video player:');
            log('   - Orientation: $orientation');
            log('   - Screen size: ${screenSize.width}x${screenSize.height}');
            log('   - Video aspect ratio: $aspectRatio');
            log(
              '   - Video size: ${controller.value.size.width}x${controller.value.size.height}',
            );
            log('   - Is landscape: $isLandscape');

            // Calculate expected video dimensions
            final videoWidth = isLandscape
                ? screenSize.width
                : screenSize.width;
            final videoHeight = isLandscape
                ? screenSize.width / aspectRatio
                : screenSize.width / aspectRatio;
            log('   - Expected video display: ${videoWidth}x$videoHeight');

            return SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video player fills entire screen - always visible
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  // Overlay with controls and gestures - on top of video
                  _buildVideoContent(controller, screenSize),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideoContent(VideoPlayerController controller, Size screenSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final videoWidth = constraints.maxWidth;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Main tap gesture detector for toggling controls
            // This needs to be below other gesture detectors but still receive taps
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                onDoubleTapDown: (details) {
                  _handleDoubleTap(
                    details,
                    Size(videoWidth, constraints.maxHeight),
                  );
                },
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // Left side gesture detector (Brightness)
            Positioned.fill(
              right: videoWidth / 2,
              child: GestureDetector(
                onVerticalDragUpdate: (details) =>
                    _handleVerticalDrag(details, true),
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // Right side gesture detector (Volume)
            Positioned.fill(
              left: videoWidth / 2,
              child: GestureDetector(
                onVerticalDragUpdate: (details) =>
                    _handleVerticalDrag(details, false),
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // Brightness Indicator
            if (_showBrightnessIndicator)
              Positioned(
                left: 40,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildIndicator(
                    Icons.brightness_6,
                    _currentBrightness,
                    'Brightness',
                  ).animate().fadeIn().scale(),
                ),
              ),

            // Volume Indicator
            if (_showVolumeIndicator)
              Positioned(
                right: 40,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildIndicator(
                    _currentVolume > 0 ? Icons.volume_up : Icons.volume_off,
                    _currentVolume,
                    'Volume',
                  ).animate().fadeIn().scale(),
                ),
              ),

            // Video Controls Overlay - only show when controls are visible
            // Put it on top so it can receive button taps
            if (_showControls)
              IgnorePointer(
                ignoring: false,
                child: VideoControlsOverlay(
                  onControlsHide: () => setState(() => _showControls = false),
                  onRotate: _rotateVideo,
                  isLandscape: _isLandscape,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIndicator(IconData icon, double value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 36),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            width: 8,
            child: RotatedBox(
              quarterTurns: 3,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.deepPurpleAccent,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(value * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Don't reset orientation here - let the screen handle it
    super.dispose();
  }
}
