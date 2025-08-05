import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'google_tts_service.dart';
import 'package:just_audio/just_audio.dart';

class TTSService {
  FlutterTts? _flutterTts;
  GoogleTTSService? _googleTTS;
  bool _isInitialized = false;

  // Enhanced voice configurations for more natural Turkish speech
  static const Map<String, Map<String, dynamic>> _voiceConfigs = {
    'professional': {
      'speechRate': 0.7, // Slower for clarity
      'volume': 1.0, // Full volume
      'language': 'tr-TR',
      'voice': 'tr-TR-Standard-A',
    },
    'friendly': {
      'speechRate': 0.8, // Slightly faster
      'volume': 1.0,
      'language': 'tr-TR',
      'voice': 'tr-TR-Standard-B',
    },
    'casual': {
      'speechRate': 0.9, // Normal speed
      'volume': 1.0,
      'language': 'tr-TR',
      'voice': 'tr-TR-Standard-C',
    },
    'energetic': {
      'speechRate': 1.0, // Fast
      'volume': 1.0,
      'language': 'tr-TR',
      'voice': 'tr-TR-Standard-D',
    },
  };

  TTSService() {
    _flutterTts = FlutterTts();
    _googleTTS = GoogleTTSService.instance;
  }

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Initialize Flutter TTS
      _flutterTts = FlutterTts();
      
      // Set default language
      await _flutterTts!.setLanguage('tr-TR');
      
      // Set default voice parameters
      await _flutterTts!.setSpeechRate(0.7);
      await _flutterTts!.setVolume(1.0);
      
      // Get available voices
      final voices = await _flutterTts!.getVoices;
      print('Available Flutter TTS voices: $voices');
      
      // Try to set a Turkish voice if available
      if (voices != null) {
        for (var voice in voices) {
          if (voice['locale'] == 'tr-TR') {
            await _flutterTts!.setVoice({"name": voice['name'], "locale": voice['locale']});
            print('Set Flutter TTS voice: ${voice['name']}');
            break;
          }
        }
      }
      
      // Initialize Google TTS as backup
      _googleTTS = GoogleTTSService.instance;
      await _googleTTS!.initialize();
      
      _isInitialized = true;
      print('Flutter TTS initialized successfully with natural settings');
    } catch (e) {
      print('TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<bool> isAvailable() async {
    if (!_isInitialized) await initialize();
    return _flutterTts != null || _googleTTS != null;
  }

  // Generate audio file with duration information
  Future<Map<String, dynamic>> generateAudioFileWithDuration(
    String text,
    String voiceStyle,
    String language,
  ) async {
    try {
      if (!_isInitialized) await initialize();
      
      await _setVoiceStyle(voiceStyle);
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'podcast_${voiceStyle}_$timestamp.mp3';
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final podcastDir = Directory('${directory.path}/podcasts');
      
      // Create directory if it doesn't exist
      if (!await podcastDir.exists()) {
        await podcastDir.create(recursive: true);
      }
      
      final filePath = '${podcastDir.path}/$filename';
      
      // Try Google TTS first (primary method)
      try {
        print('Attempting Google TTS generation...');
        final audioData = await _generateGoogleTTSAudio(text, voiceStyle);
        if (audioData != null && audioData.isNotEmpty) {
          final file = File(filePath);
          await file.writeAsBytes(audioData);
          print('Google TTS audio file created: $filePath');
          print('Audio file size: ${await file.length()} bytes');
          
          // Get duration from the generated file
          final duration = await _getAudioDuration(filePath);
          return {
            'filePath': filePath,
            'duration': duration,
            'method': 'google_tts',
          };
        } else {
          print('Google TTS returned null or empty audio data');
        }
      } catch (e) {
        print('Google TTS failed: $e');
      }
      
      // Try Flutter TTS as backup
      try {
        print('Attempting Flutter TTS generation...');
        final audioData = await _generateFlutterTTSAudio(text);
        if (audioData != null && audioData.isNotEmpty) {
          final file = File(filePath);
          await file.writeAsBytes(audioData);
          print('Flutter TTS audio file created: $filePath');
          print('Audio file size: ${await file.length()} bytes');
          
          // Get duration from the generated file
          final duration = await _getAudioDuration(filePath);
          return {
            'filePath': filePath,
            'duration': duration,
            'method': 'flutter_tts',
          };
        } else {
          print('Flutter TTS returned null or empty audio data');
        }
      } catch (e) {
        print('Flutter TTS failed: $e');
      }
      
      throw Exception('TTS service failed to generate audio');
      
    } catch (e) {
      print('Audio generation error: $e');
      rethrow;
    }
  }

  // Get audio duration from file
  Future<Duration> _getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found: $filePath');
      }

      print('Getting duration for TTS file: $filePath');
      print('File size: ${await file.length()} bytes');

      // Use just_audio package to get duration
      final player = AudioPlayer();
      
      try {
        await player.setFilePath(filePath);
        
        // Wait a bit for the player to load the file
        await Future.delayed(const Duration(milliseconds: 500));
        
        final duration = player.duration;
        
        if (duration != null) {
          print('TTS audio duration: ${duration.inSeconds} seconds (${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')})');
          return duration;
        } else {
          // If duration is null, try alternative method
          print('TTS duration is null, trying alternative method...');
          
          // Try to get duration by playing a small portion
          await player.seek(Duration.zero);
          await player.play();
          await Future.delayed(const Duration(milliseconds: 100));
          await player.pause();
          
          final alternativeDuration = player.duration;
          if (alternativeDuration != null) {
            print('Alternative TTS duration method successful: ${alternativeDuration.inSeconds} seconds');
            return alternativeDuration;
          }
          
          throw Exception('Could not determine TTS audio duration - both methods failed');
        }
      } finally {
        await player.dispose();
      }
    } catch (e) {
      print('Error getting TTS audio duration: $e');
      
      // Fallback: estimate duration based on file size and bitrate
      try {
        final file = File(filePath);
        final fileSize = await file.length();
        
        // Estimate duration based on typical MP3 bitrate (128 kbps)
        // Formula: duration = file_size / (bitrate / 8)
        const bitrate = 128 * 1024; // 128 kbps in bits per second
        final estimatedSeconds = (fileSize * 8) / bitrate;
        final estimatedDuration = Duration(seconds: estimatedSeconds.round());
        
        print('Using estimated TTS duration: ${estimatedDuration.inSeconds} seconds (based on file size)');
        return estimatedDuration;
      } catch (fallbackError) {
        print('Fallback TTS duration estimation failed: $fallbackError');
        
        // Final fallback: return a default duration
        const defaultDuration = Duration(minutes: 5);
        print('Using default TTS duration: ${defaultDuration.inMinutes} minutes');
        return defaultDuration;
      }
    }
  }

  Future<String> generateAudioFile(
    String text,
    String voiceStyle,
    String language,
  ) async {
    try {
      if (!_isInitialized) await initialize();
      
      // Set voice style
      await _setVoiceStyle(voiceStyle);
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'podcast_${voiceStyle}_$timestamp.mp3';
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final podcastDir = Directory('${directory.path}/podcasts');
      
      // Create directory if it doesn't exist
      if (!await podcastDir.exists()) {
        await podcastDir.create(recursive: true);
      }
      
      final filePath = '${podcastDir.path}/$filename';
      
      // Try Google TTS first (primary method)
      try {
        print('Attempting Google TTS generation...');
        final audioData = await _generateGoogleTTSAudio(text, voiceStyle);
        if (audioData != null && audioData.isNotEmpty) {
          final file = File(filePath);
          await file.writeAsBytes(audioData);
          print('Google TTS audio file created: $filePath');
          print('Audio file size: ${await file.length()} bytes');
          return filePath;
        } else {
          print('Google TTS returned null or empty audio data');
        }
      } catch (e) {
        print('Google TTS failed: $e');
      }
      
      // Try Flutter TTS as backup
      try {
        print('Attempting Flutter TTS generation...');
        final audioData = await _generateFlutterTTSAudio(text);
        if (audioData != null && audioData.isNotEmpty) {
          final file = File(filePath);
          await file.writeAsBytes(audioData);
          print('Flutter TTS audio file created: $filePath');
          print('Audio file size: ${await file.length()} bytes');
          return filePath;
        } else {
          print('Flutter TTS returned null or empty audio data');
        }
      } catch (e) {
        print('Flutter TTS failed: $e');
      }
      
      throw Exception('TTS service failed to generate audio');
      
    } catch (e) {
      print('Audio generation error: $e');
      rethrow;
    }
  }

  Future<void> _setVoiceStyle(String voiceStyle) async {
    try {
      final config = _voiceConfigs[voiceStyle] ?? _voiceConfigs['professional']!;
      
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(config['speechRate']);
        await _flutterTts!.setVolume(config['volume']);
        await _flutterTts!.setLanguage(config['language']);
        
        // Try to set voice if available
        try {
          await _flutterTts!.setVoice({"name": config['voice'], "locale": config['language']});
        } catch (e) {
          print('Voice setting failed, using default: $e');
        }
      }
      
      print('Voice style set to: $voiceStyle with natural parameters');
    } catch (e) {
      print('Voice style setting error: $e');
    }
  }

  Future<Uint8List?> _generateFlutterTTSAudio(String text) async {
    try {
      if (_flutterTts == null) return null;
      
      // Generate audio data using synthesizeToFile with proper parameters
      final tempFile = await _flutterTts!.synthesizeToFile(text, 'temp_audio');
      if (tempFile != null) {
        final file = File(tempFile);
        if (await file.exists()) {
          final data = await file.readAsBytes();
          await file.delete(); // Clean up temp file
          return data;
        }
      }
      
      return null;
    } catch (e) {
      print('Flutter TTS audio generation error: $e');
      return null;
    }
  }

  Future<Uint8List?> _generateGoogleTTSAudio(String text, String voiceStyle) async {
    try {
      if (_googleTTS == null) {
        print('Google TTS service is null');
        return null;
      }
      
      final config = _voiceConfigs[voiceStyle] ?? _voiceConfigs['professional']!;
      print('Using Google TTS with config: $config');
      
      // Generate audio file using Google TTS
      final filePath = await _googleTTS!.generateAudioFile(
        text,
        voiceStyle,
        config['language'],
      );
      
      print('Google TTS generated file path: $filePath');
      
      // Read the generated file and return as Uint8List
      final file = File(filePath);
      if (await file.exists()) {
        final audioData = await file.readAsBytes();
        print('Google TTS audio data size: ${audioData.length} bytes');
        
        // Check if audio data is valid (not just placeholder)
        if (audioData.length > 1000) {
          return audioData;
        } else {
          print('Google TTS returned invalid audio data (too small)');
          return null;
        }
      } else {
        print('Google TTS generated file does not exist: $filePath');
        return null;
      }
    } catch (e) {
      print('Google TTS audio generation error: $e');
      return null;
    }
  }

  // Speak text directly (for real-time speech)
  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) await initialize();
      
      if (_flutterTts != null) {
        await _flutterTts!.speak(text);
      } else {
        print('TTS not available for real-time speech');
      }
    } catch (e) {
      print('Error speaking text: $e');
      rethrow;
    }
  }

  // Stop current speech
  Future<void> stop() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  // Pause current speech
  Future<void> pause() async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.pause();
      }
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    try {
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(rate);
      }
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  // Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      if (_flutterTts != null) {
        final voices = await _flutterTts!.getVoices;
        return List<Map<String, String>>.from(voices);
      }
      return [];
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  // Get available languages
  Future<List<Map<String, String>>> getAvailableLanguages() async {
    try {
      if (_flutterTts != null) {
        final languages = await _flutterTts!.getLanguages;
        return List<Map<String, String>>.from(languages);
      }
      return [];
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  // Test TTS functionality
  Future<Map<String, dynamic>> testTTS(String text, String voiceStyle) async {
    try {
      final startTime = DateTime.now();
      
      final audioFilePath = await generateAudioFile(
        text,
        voiceStyle,
        'tr-TR',
      );
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      final audioFile = File(audioFilePath);
      final fileSize = await audioFile.exists() ? await audioFile.length() : 0;
      
      return {
        'success': true,
        'audioFilePath': audioFilePath,
        'fileSize': fileSize,
        'processingTime': duration,
        'voiceStyle': voiceStyle,
        'textLength': text.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'voiceStyle': voiceStyle,
        'textLength': text.length,
      };
    }
  }
} 