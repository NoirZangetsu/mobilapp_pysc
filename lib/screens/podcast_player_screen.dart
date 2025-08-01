import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class PodcastPlayerScreen extends StatefulWidget {
  final Podcast podcast;

  const PodcastPlayerScreen({
    super.key,
    required this.podcast,
  });

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.podcast.duration;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        title: Text(
          'Podcast Dinle',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.headingText),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.accentBlue),
            onPressed: () {
              // Share functionality would be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaş özelliği yakında eklenecek')),
              );
            },
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Podcast info
            _buildPodcastInfo(),
            
            // Player controls
            Expanded(
              child: _buildPlayerControls(),
            ),
            
            // Progress bar
            _buildProgressBar(),
            
            // Control buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Podcast image placeholder with gradient
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.2),
                  AppColors.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.headphones,
              size: 80,
              color: AppColors.accentBlue,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            widget.podcast.title,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Description
          if (widget.podcast.description != null)
            Text(
              widget.podcast.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          
          const SizedBox(height: 16),
          
          // Podcast metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(widget.podcast.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timer,
                size: 16,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(widget.podcast.duration),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              if (widget.podcast.listenCount != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.podcast.listenCount} dinleme',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Current time and total time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Play/Pause button with animation
          GestureDetector(
            onTap: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
              // TODO: Implement actual audio playback
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isPlaying 
                      ? [
                          AppColors.accentBlue,
                          AppColors.accentBlue.withValues(alpha: 0.8),
                        ]
                      : [
                          AppColors.accentBlue.withValues(alpha: 0.8),
                          AppColors.accentBlue,
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Additional controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.skip_previous,
                onPressed: () {
                  // TODO: Implement previous track
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Önceki parça özelliği yakında eklenecek')),
                  );
                },
                tooltip: 'Önceki',
              ),
              _buildControlButton(
                icon: Icons.replay_10,
                onPressed: () {
                  // TODO: Implement rewind 10 seconds
                  setState(() {
                    _currentPosition = Duration(
                      seconds: (_currentPosition.inSeconds - 10).clamp(0, _totalDuration.inSeconds),
                    );
                  });
                },
                tooltip: '10 saniye geri',
              ),
              _buildControlButton(
                icon: Icons.forward_10,
                onPressed: () {
                  // TODO: Implement forward 10 seconds
                  setState(() {
                    _currentPosition = Duration(
                      seconds: (_currentPosition.inSeconds + 10).clamp(0, _totalDuration.inSeconds),
                    );
                  });
                },
                tooltip: '10 saniye ileri',
              ),
              _buildControlButton(
                icon: Icons.skip_next,
                onPressed: () {
                  // TODO: Implement next track
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sonraki parça özelliği yakında eklenecek')),
                  );
                },
                tooltip: 'Sonraki',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.accentBlue),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.accentBlue,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 4,
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0 
                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
                  : 0.0,
              onChanged: (value) {
                setState(() {
                  _currentPosition = Duration(
                    milliseconds: (value * _totalDuration.inMilliseconds).round(),
                  );
                });
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Progress info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Speed control
          _buildControlButton(
            icon: Icons.speed,
            onPressed: () {
              // TODO: Implement playback speed control
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hız kontrolü yakında eklenecek')),
              );
            },
            tooltip: 'Hız',
          ),
          
          // Volume control
          _buildControlButton(
            icon: Icons.volume_up,
            onPressed: () {
              // TODO: Implement volume control
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ses kontrolü yakında eklenecek')),
              );
            },
            tooltip: 'Ses',
          ),
          
          // Favorite
          _buildControlButton(
            icon: Icons.favorite_border,
            onPressed: () {
              // TODO: Implement favorite functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Favorilere eklendi')),
              );
            },
            tooltip: 'Favori',
          ),
          
          // Download
          _buildControlButton(
            icon: Icons.download,
            onPressed: () {
              // TODO: Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İndirme özelliği yakında eklenecek')),
              );
            },
            tooltip: 'İndir',
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
} 