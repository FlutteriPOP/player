import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../models/video_model.dart';
import '../providers/video_provider.dart';
import '../services/file_picker_service.dart';
import '../services/orientation_service.dart';
import '../services/share_service.dart';
import '../services/toast_service.dart';
import '../services/video_history_service.dart';
import '../services/video_scanner_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/recent_videos_widget.dart';
import '../widgets/video_card_widget.dart';
import 'statistics_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<VideoModel> _recentVideos = [];
  List<VideoModel> _scannedVideos = [];
  bool _isScanning = false;
  int _selectedTabIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    OrientationService.lockPortrait();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadRecentVideos();
    // Auto-scan on app start
    _scanForVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentVideos() async {
    final videos = await VideoHistoryService.getRecentVideos();
    if (mounted) {
      setState(() => _recentVideos = videos);
    }
  }

  Future<void> _scanForVideos() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      ToastService.showInfo('Scanning for videos...');
      final videos = await VideoScannerService.scanForVideos();

      if (mounted) {
        setState(() {
          _scannedVideos = videos;
          _isScanning = false;
        });

        if (videos.isEmpty) {
          ToastService.showWarning('No videos found on device');
        } else {
          ToastService.showSuccess('Found ${videos.length} video(s)');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ToastService.showError('Error scanning videos: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
              Colors.deepPurple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Consumer<VideoProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return _buildLoadingState();
                    }

                    return Column(
                      children: [
                        _buildTabBar(),
                        Expanded(
                          child: _selectedTabIndex == 0
                              ? _buildRecentVideosList()
                              : _buildScannedVideosList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickVideo(context),
        icon: const Icon(Icons.video_library),
        label: const Text('Pick Video'),
        backgroundColor: Colors.deepPurple,
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.deepPurpleAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Video Player Pro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search, color: Colors.white),
            onPressed: _isScanning ? null : _scanForVideos,
            tooltip: 'Scan for Videos',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () => _showStatistics(context),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showRecentVideos(context),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.deepPurpleAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(icon: Icon(Icons.history), text: 'Recent'),
          Tab(icon: Icon(Icons.video_library), text: 'All Videos'),
        ],
      ),
    );
  }

  Widget _buildRecentVideosList() {
    if (_recentVideos.isEmpty) {
      return const EmptyStateWidget();
    }

    return RefreshIndicator(
      onRefresh: _loadRecentVideos,
      color: Colors.deepPurpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Recent Videos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                itemCount: _recentVideos.length,
                itemBuilder: (context, index) {
                  final video = _recentVideos[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: VideoCardWidget(
                          video: video,
                          index: index,
                          onTap: () => _playVideo(video),
                          onDelete: () => _deleteVideo(video),
                          onShare: () => _shareVideo(video),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedVideosList() {
    if (_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.deepPurpleAccent,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning for videos...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    if (_scannedVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No videos found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the search icon to scan for videos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _scanForVideos,
              icon: const Icon(Icons.search),
              label: const Text('Scan Now'),
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
        ).animate().fadeIn(),
      );
    }

    return RefreshIndicator(
      onRefresh: _scanForVideos,
      color: Colors.deepPurpleAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'All Videos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_scannedVideos.length}',
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _scanForVideos,
                  tooltip: 'Rescan',
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                itemCount: _scannedVideos.length,
                itemBuilder: (context, index) {
                  final video = _scannedVideos[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: VideoCardWidget(
                          video: video,
                          index: index,
                          onTap: () => _playVideo(video),
                          onDelete: () => _deleteVideo(video),
                          onShare: () => _shareVideo(video),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.deepPurpleAccent,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Loading video...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Future<void> _pickVideo(BuildContext context) async {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    final path = await FilePickerService.pickVideo(context);

    if (path != null && context.mounted) {
      final success = await provider.loadVideo(path);
      if (context.mounted && success && provider.hasVideo) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VideoPlayerScreen()),
        );
        if (context.mounted) {
          await OrientationService.lockPortrait();
          _loadRecentVideos();
        }
      } else if (context.mounted && !success) {
        ToastService.showError(provider.errorMessage ?? 'Failed to load video');
      }
    }
  }

  Future<void> _playVideo(VideoModel video) async {
    final provider = Provider.of<VideoProvider>(context, listen: false);

    // Check if file exists
    if (!await video.exists()) {
      ToastService.showError('Video file not found');
      await VideoHistoryService.removeFromHistory(video.path);
      _loadRecentVideos();
      return;
    }

    final success = await provider.loadVideo(video.path);
    if (mounted && success && provider.hasVideo) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VideoPlayerScreen()),
      );
      if (mounted) {
        await OrientationService.lockPortrait();
        _loadRecentVideos();
        // Refresh scanned videos in case file was deleted
        if (_selectedTabIndex == 1) {
          setState(() {
            _scannedVideos.removeWhere((v) => !File(v.path).existsSync());
          });
        }
      }
    } else if (mounted && !success) {
      ToastService.showError(provider.errorMessage ?? 'Failed to load video');
      // Remove from scanned list if file doesn't exist
      if (_selectedTabIndex == 1) {
        setState(() {
          _scannedVideos.removeWhere((v) => v.path == video.path);
        });
      }
    }
  }

  Future<void> _deleteVideo(VideoModel video) async {
    final isInRecent = _recentVideos.any((v) => v.path == video.path);
    final isInScanned = _scannedVideos.any((v) => v.path == video.path);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isInRecent ? 'Remove from History' : 'Remove Video'),
        content: Text(
          isInRecent
              ? 'Remove "${video.name}" from history?'
              : 'Remove "${video.name}" from list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isInRecent) {
        await VideoHistoryService.removeFromHistory(video.path);
        ToastService.showSuccess('Removed from history');
        _loadRecentVideos();
      }

      if (isInScanned) {
        setState(() {
          _scannedVideos.removeWhere((v) => v.path == video.path);
        });
        ToastService.showSuccess('Removed from list');
      }
    }
  }

  Future<void> _shareVideo(VideoModel video) async {
    try {
      final file = File(video.path);
      if (!await file.exists()) {
        ToastService.showError('Video file not found');
        return;
      }

      final shareService = ShareService();
      await shareService.shareVideo(video);
    } catch (e) {
      ToastService.showError('Failed to share video: ${e.toString()}');
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all video history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VideoHistoryService.clearHistory();
      ToastService.showSuccess('History cleared');
      _loadRecentVideos();
    }
  }

  void _showRecentVideos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const RecentVideosWidget(),
    );
  }

  void _showStatistics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
    );
  }
}
