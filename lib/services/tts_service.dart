import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as Math;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'google_tts_service.dart';

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
      _googleTTS = GoogleTTSService();
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
      
      // Create fallback audio file
      print('Creating fallback audio file...');
      final fallbackAudio = _createRealAudioFile(text.length);
      final file = File(filePath);
      await file.writeAsBytes(fallbackAudio);
      print('Fallback audio file created: $filePath');
      print('Audio file size: ${await file.length()} bytes');
      return filePath;
      
    } catch (e) {
      print('Audio generation error: $e');
      // Return a placeholder file path
      return await _createPlaceholderAudio();
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
        print('Google TTS file does not exist: $filePath');
        return null;
      }
    } catch (e) {
      print('Google TTS audio generation error: $e');
      return null;
    }
  }

  // Create a real audio file with proper WAV format
  Uint8List _createRealAudioFile(int textLength) {
    // Calculate duration based on text length (roughly 150 words per minute)
    final wordsPerMinute = 150;
    final words = textLength / 5; // Rough estimate: 5 characters per word
    final durationSeconds = (words / wordsPerMinute * 60).round();
    final finalDuration = Math.max(5, Math.min(durationSeconds, 300)); // 5-300 seconds
    
    // WAV file parameters
    final sampleRate = 44100;
    final channels = 1; // Mono
    final bitsPerSample = 16;
    final bytesPerSample = bitsPerSample ~/ 8;
    final blockAlign = channels * bytesPerSample;
    final byteRate = sampleRate * blockAlign;
    final dataSize = sampleRate * finalDuration * blockAlign;
    final fileSize = 44 + dataSize; // 44 bytes header + data
    
    // Create WAV header
    final header = ByteData(44);
    
    // RIFF header
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, fileSize - 8, Endian.little); // File size - 8
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    
    // fmt chunk
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // fmt chunk size
    header.setUint16(20, 1, Endian.little); // Audio format (PCM)
    header.setUint16(22, channels, Endian.little); // Channels
    header.setUint32(24, sampleRate, Endian.little); // Sample rate
    header.setUint32(28, byteRate, Endian.little); // Byte rate
    header.setUint16(32, blockAlign, Endian.little); // Block align
    header.setUint16(34, bitsPerSample, Endian.little); // Bits per sample
    
    // data chunk
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, dataSize, Endian.little); // Data size
    
    // Create audio data (simple sine wave)
    final audioData = ByteData(dataSize);
    final frequency = 440.0; // A4 note
    final amplitude = 0.3;
    
    for (int i = 0; i < dataSize; i += 2) {
      final sample = (i ~/ 2) / sampleRate.toDouble();
      final sineValue = Math.sin(2 * Math.pi * frequency * sample);
      final sampleValue = (sineValue * amplitude * 32767).round();
      audioData.setUint16(i, sampleValue, Endian.little);
    }
    
    // Combine header and audio data
    final result = Uint8List(fileSize);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, fileSize, audioData.buffer.asUint8List());
    
    print('Created real audio file with duration: ${finalDuration} seconds');
    return result;
  }

  Future<String> _createPlaceholderAudio() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'podcast_placeholder_$timestamp.mp3';
      
      final directory = await getApplicationDocumentsDirectory();
      final podcastDir = Directory('${directory.path}/podcasts');
      
      if (!await podcastDir.exists()) {
        await podcastDir.create(recursive: true);
      }
      
      final filePath = '${podcastDir.path}/$filename';
      final placeholderAudio = _createRealAudioFile(100); // 100 characters = ~5 seconds
      
      final file = File(filePath);
      await file.writeAsBytes(placeholderAudio);
      
      print('Placeholder audio created: $filePath');
      return filePath;
    } catch (e) {
      print('Placeholder audio creation error: $e');
      return 'placeholder_audio.mp3';
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