import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import '../providers/video_provider.dart';
import '../services/video_history_service.dart';
import '../models/video_model.dart';
import '../screens/video_player_screen.dart';

class RecentVideosWidget extends StatefulWidget {
  const RecentVideosWidget({super.key});

  @override
  State<RecentVideosWidget> createState() => _RecentVideosWidgetState();
}

class _RecentVideosWidgetState extends State<RecentVideosWidget> {
  List<VideoModel> _recentVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentVideos();
  }

  Future<void> _loadRecentVideos() async {
    setState(() => _isLoading = true);
    final videos = await VideoHistoryService.getRecentVideos();
    setState(() {
      _recentVideos = videos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(child: _buildVideoList(context)),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history,
              color: Colors.deepPurpleAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Recent Videos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      );
    }

    if (_recentVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent videos',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentVideos.length,
      itemBuilder: (context, index) {
        final video = _recentVideos[index];
        final file = File(video.path);
        final exists = file.existsSync();

        return _buildVideoItem(context, video, exists, index);
      },
    );
  }

  Widget _buildVideoItem(
    BuildContext context,
    VideoModel video,
    bool exists,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: exists
                ? Colors.deepPurple.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            exists ? Icons.play_circle_filled : Icons.error_outline,
            color: exists ? Colors.deepPurpleAccent : Colors.red,
            size: 28,
          ),
        ),
        title: Text(
          video.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          exists ? 'Tap to play' : 'File not found',
          style: TextStyle(
            color: exists ? Colors.grey.shade400 : Colors.red.shade300,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: exists
            ? () async {
                Navigator.pop(context);
                final provider = Provider.of<VideoProvider>(
                  context,
                  listen: false,
                );
                await provider.loadVideo(video.path);
                if (context.mounted && provider.hasVideo) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VideoPlayerScreen(),
                    ),
                  );
                }
              }
            : null,
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.2, end: 0);
  }
}
