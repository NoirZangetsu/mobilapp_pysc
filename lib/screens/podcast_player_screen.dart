import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../models/podcast.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'package:path_provider/path_provider.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      print('Initializing audio player for: ${widget.podcast.audioUrl}');
      
      // Check if file exists and get its size
      final audioFile = File(widget.podcast.audioUrl);
      if (await audioFile.exists()) {
        final fileSize = await audioFile.length();
        print('File size: $fileSize bytes');
        
        // Check if file is too small (placeholder)
        if (fileSize < 1000) {
          setState(() {
            _error = 'Ses dosyası çok küçük, gerçek ses dosyası değil';
            _isLoading = false;
          });
          return;
        }
        
        // Initialize the audio player
        await _audioPlayer.setFilePath(widget.podcast.audioUrl);
        
        // Set up player listeners
        _audioPlayer.playerStateStream.listen((state) {
          print('Player state: ${state.processingState}, playing: ${state.playing}');
          
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
              if (state.processingState == ProcessingState.completed) {
                _isPlaying = false;
                _currentPosition = Duration.zero;
              }
            });
          }
        });
        
        // Listen to position changes
        _audioPlayer.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
          }
        });
        
        // Listen to duration changes
        _audioPlayer.durationStream.listen((duration) {
          if (mounted && duration != null) {
            setState(() {
              _totalDuration = duration;
              print('Audio duration: ${duration.inSeconds} seconds');
            });
          }
        });
        
        // Set initial duration from podcast metadata
        if (widget.podcast.duration != Duration.zero) {
          setState(() {
            _totalDuration = widget.podcast.duration;
            print('Set duration from metadata: ${_totalDuration.inSeconds} seconds');
          });
        }
        
        // Ensure player starts paused
        await _audioPlayer.pause();
        
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        
        print('Audio player initialized successfully');
      } else {
        print('Audio file not found: ${widget.podcast.audioUrl}');
        setState(() {
          _error = 'Ses dosyası bulunamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Audio player initialization error: $e');
      setState(() {
        _error = 'Ses dosyası yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error playing/pausing: $e');
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  Future<void> _skipForward() async {
    try {
      final newPosition = _currentPosition + const Duration(seconds: 10);
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      print('Error skipping forward: $e');
    }
  }

  Future<void> _skipBackward() async {
    try {
      final newPosition = _currentPosition - const Duration(seconds: 10);
      await _audioPlayer.seek(newPosition);
    } catch (e) {
      print('Error skipping backward: $e');
    }
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
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.accentBlue),
            onPressed: () {
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
            // Podcast info - more compact
            _buildPodcastInfo(),
            
            // Progress bar - more compact
            _buildProgressBar(),
            
            // Player controls - more compact
            Expanded(
              child: _buildPlayerControls(),
            ),
            
            // Control buttons - more compact
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Podcast image placeholder - smaller size
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.2),
                  AppColors.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.headphones,
              size: 60,
              color: AppColors.accentBlue,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title - with overflow protection
          Text(
            widget.podcast.title,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Description - with overflow protection
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
          
          const SizedBox(height: 12),
          
          // Metadata - more compact
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule,
                size: 14,
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
                size: 14,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(widget.podcast.duration),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.accentBlue,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 3,
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0 
                  ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds 
                  : 0.0,
              onChanged: (value) async {
                final newPosition = Duration(
                  milliseconds: (value * _totalDuration.inMilliseconds).round(),
                );
                try {
                  await _audioPlayer.seek(newPosition);
                } catch (e) {
                  print('Error seeking: $e');
                }
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progress info - more compact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ses dosyası yükleniyor...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.errorRed,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeAudioPlayer,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skip backward button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _skipBackward,
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 20),
              
              // Main play/pause button
              GestureDetector(
                onTap: _playPause,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Skip forward button
              IconButton(
                onPressed: _skipForward,
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
                color: AppColors.accentBlue,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Playback speed controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSpeedButton(0.5, '0.5x'),
              const SizedBox(width: 8),
              _buildSpeedButton(0.75, '0.75x'),
              const SizedBox(width: 8),
              _buildSpeedButton(1.0, '1x'),
              const SizedBox(width: 8),
              _buildSpeedButton(1.25, '1.25x'),
              const SizedBox(width: 8),
              _buildSpeedButton(1.5, '1.5x'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton(double speed, String label) {
    return GestureDetector(
      onTap: () => _setPlaybackSpeed(speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.accentBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oynatma hızı: ${speed}x')),
      );
    } catch (e) {
      print('Error setting playback speed: $e');
    }
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
        icon: Icon(icon, color: AppColors.accentBlue, size: 20),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Script button
          IconButton(
            onPressed: () => _showScriptDialog(),
            icon: const Icon(Icons.description),
            tooltip: 'Script Göster',
            color: AppColors.accentBlue,
          ),
          
          // Share button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paylaş özelliği yakında eklenecek')),
              );
            },
            icon: const Icon(Icons.share),
            tooltip: 'Paylaş',
            color: AppColors.accentBlue,
          ),
          
          // Settings button
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            color: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }

  void _showScriptDialog() {
    if (widget.podcast.script == null || widget.podcast.script!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu podcast için script bulunamadı')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Podcast Script\'i'),
        content: SingleChildScrollView(
          child: Text(
            widget.podcast.script!,
            style: AppTextStyles.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oynatma Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Oynatma Hızı'),
              subtitle: const Text('Ses hızını ayarlayın'),
              onTap: () {
                Navigator.pop(context);
                _showSpeedDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.equalizer),
              title: const Text('Ses Ayarları'),
              subtitle: const Text('Bass, treble ayarları'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ses ayarları yakında eklenecek')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oynatma Hızı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption(0.5, '0.5x - Yavaş'),
            _buildSpeedOption(0.75, '0.75x - Yavaş'),
            _buildSpeedOption(1.0, '1x - Normal'),
            _buildSpeedOption(1.25, '1.25x - Hızlı'),
            _buildSpeedOption(1.5, '1.5x - Çok Hızlı'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(double speed, String label) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.check),
      onTap: () {
        _setPlaybackSpeed(speed);
        Navigator.pop(context);
        Navigator.pop(context);
      },
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