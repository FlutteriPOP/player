import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/video_provider.dart';

class VideoControlsOverlay extends StatefulWidget {
  final VoidCallback onControlsHide;
  final VoidCallback onRotate;
  final bool isLandscape;

  const VideoControlsOverlay({
    super.key,
    required this.onControlsHide,
    required this.onRotate,
    required this.isLandscape,
  });

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        widget.onControlsHide();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        final controller = provider.videoPlayerController;
        if (controller == null) return const SizedBox.shrink();

        return IgnorePointer(
          ignoring: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopBar(context),
                _buildCenterControls(controller),
                _buildBottomBar(controller),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => _showSettingsMenu(context),
                tooltip: 'Settings',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls(VideoPlayerController controller) {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(Icons.replay_10, () {
          final position = controller.value.position;
          provider.seekTo(position - const Duration(seconds: 10));
        }),
        const SizedBox(width: 24),
        _buildControlButton(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          () {
            provider.togglePlayPause();
            setState(() {});
          },
          size: 64,
        ),
        const SizedBox(width: 24),
        _buildControlButton(Icons.forward_10, () {
          final position = controller.value.position;
          final duration = controller.value.duration;
          final newPosition = position + const Duration(seconds: 10);
          provider.seekTo(newPosition < duration ? newPosition : duration);
        }),
      ],
    );
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed, {
    double size = 48,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size),
          onTap: onPressed,
          child: Container(
            width: size + 16,
            height: size + 16,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: size * 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(VideoPlayerController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, VideoPlayerValue value, child) {
                final provider = Provider.of<VideoProvider>(
                  context,
                  listen: false,
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                          disabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 20,
                        ),
                        activeTrackColor: Colors.deepPurpleAccent,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: Colors.deepPurpleAccent,
                        overlayColor: Colors.deepPurpleAccent.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      child: Slider(
                        value: value.position.inMilliseconds.toDouble(),
                        min: 0,
                        max: value.duration.inMilliseconds.toDouble(),
                        onChangeStart: (_) {
                          setState(() => _isDragging = true);
                        },
                        onChanged: (val) {
                          provider.seekTo(Duration(milliseconds: val.toInt()));
                        },
                        onChangeEnd: (_) {
                          setState(() => _isDragging = false);
                          _startHideTimer();
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _formatDuration(value.duration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            // Bottom Controls
            Row(
              children: [
                _buildBottomControlButton(
                  icon: controller.value.volume > 0
                      ? Icons.volume_up
                      : Icons.volume_off,
                  onPressed: () {
                    final provider = Provider.of<VideoProvider>(
                      context,
                      listen: false,
                    );
                    if (controller.value.volume > 0) {
                      provider.setVolume(0);
                    } else {
                      provider.setVolume(1);
                    }
                    setState(() {});
                  },
                  tooltip: controller.value.volume > 0 ? 'Mute' : 'Unmute',
                ),
                const Spacer(),
                _buildBottomControlButton(
                  icon: Icons.speed,
                  onPressed: () => _showSpeedMenu(context, controller),
                  tooltip: 'Playback Speed',
                ),
                const SizedBox(width: 8),
                _buildBottomControlButton(
                  icon: Icons.screen_rotation,
                  onPressed: widget.onRotate,
                  tooltip: widget.isLandscape
                      ? 'Rotate to Portrait'
                      : 'Rotate to Landscape',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedMenu(BuildContext context, VideoPlayerController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final provider = Provider.of<VideoProvider>(context, listen: false);
        final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Playback Speed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...speeds.map((speed) {
                    final isSelected = controller.value.playbackSpeed == speed;
                    return ListTile(
                      title: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.deepPurpleAccent
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.deepPurpleAccent,
                            )
                          : null,
                      onTap: () {
                        provider.setPlaybackSpeed(speed);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 24,
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Gesture Controls',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Swipe left: Brightness\nSwipe right: Volume\nDouble tap: Skip 10s',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.screen_rotation,
                      color: Colors.white,
                    ),
                    title: const Text(
                      'Rotation',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Tap the rotation button to switch between portrait and landscape mode',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
