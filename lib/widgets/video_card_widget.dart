import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/video_model.dart';
import '../utils/formatters.dart';

class VideoCardWidget extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final int index;

  const VideoCardWidget({
    super.key,
    required this.video,
    required this.onTap,
    this.onDelete,
    this.onShare,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
          key: ValueKey(video.path),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              if (onShare != null)
                SlidableAction(
                  onPressed: (_) => onShare!(),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.share,
                  label: 'Share',
                ),
              if (onDelete != null)
                SlidableAction(
                  onPressed: (_) => onDelete!(),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
            ],
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Thumbnail
                    _buildThumbnail(),
                    const SizedBox(width: 12),
                    // Video Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title
                          Text(
                            video.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Metadata
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (video.duration != null)
                                _buildMetadataRow(
                                  Icons.access_time,
                                  Formatters.formatDurationShort(
                                    video.duration!,
                                  ),
                                ),
                              if (video.fileSize != null)
                                _buildMetadataRow(
                                  Icons.storage,
                                  Formatters.formatFileSize(video.fileSize!),
                                ),
                              if (video.lastPlayed != null)
                                _buildMetadataRow(
                                  Icons.history,
                                  Formatters.formatRelativeTime(
                                    video.lastPlayed!,
                                  ),
                                ),
                            ],
                          ),
                          // Progress bar
                          if (video.isPartiallyWatched)
                            LinearProgressIndicator(
                              value: video.watchProgress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepPurpleAccent,
                              ),
                              minHeight: 3,
                            ),
                        ],
                      ),
                    ),
                    // Play count badge
                    if (video.playCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              size: 16,
                              color: Colors.deepPurpleAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${video.playCount}',
                              style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildThumbnail() {
    return Container(
      width: 100,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade800,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: video.thumbnailPath != null
            ? Image.file(
                File(video.thumbnailPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultThumbnail(),
              )
            : _buildDefaultThumbnail(),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      color: Colors.deepPurple.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(
          Icons.video_library,
          size: 40,
          color: Colors.deepPurpleAccent,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white60),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
