import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.withValues(alpha: 0.3),
                      Colors.deepPurple.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.video_library_outlined,
                  size: 100,
                  color: Colors.deepPurpleAccent,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 2000.ms,
                color: Colors.white.withValues(alpha: 0.3),
              )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms),
          const SizedBox(height: 32),
          const Text(
            'No Video Selected',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
          Text(
            'Tap the button below to pick a video',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 40),
          _buildFeaturesList().animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.play_circle_outline, 'text': 'Play any video format'},
      {'icon': Icons.fullscreen, 'text': 'Fullscreen support'},
      {'icon': Icons.volume_up, 'text': 'Volume control'},
      {'icon': Icons.history, 'text': 'Recent videos history'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  feature['icon'] as IconData,
                  color: Colors.deepPurpleAccent,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  feature['text'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
