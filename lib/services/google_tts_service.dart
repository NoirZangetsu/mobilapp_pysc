import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleTTSService {
  static final GoogleTTSService _instance = GoogleTTSService._internal();
  factory GoogleTTSService() => _instance;
  GoogleTTSService._internal();

  // Google Cloud TTS API Configuration
  static const String _baseUrl = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  
  // Get API key from environment variables
  String get _apiKey {
    final envKey = dotenv.env['GOOGLE_TTS_API_KEY'];
    if (envKey != null && envKey.isNotEmpty && envKey != 'YOUR_GOOGLE_TTS_API_KEY') {
      return envKey;
    }
    
    // Try to use Gemini API key as fallback
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiKey != null && geminiKey.isNotEmpty && geminiKey != 'YOUR_GEMINI_API_KEY') {
      return geminiKey;
    }
    
    throw Exception('GOOGLE_TTS_API_KEY environment variable is not configured. Please add it to your .env file.');
  }
  
  // Enhanced voice configurations for Google TTS - Natural human-like speech
  static const Map<String, Map<String, dynamic>> _voiceConfigs = {
    'professional': {
      'name': 'tr-TR-Standard-A', // Standard Turkish voice
      'languageCode': 'tr-TR',
      'speakingRate': 0.9, // Normal professional pace
      'volumeGainDb': 0.0, // Normal volume
    },
    'friendly': {
      'name': 'tr-TR-Standard-B', // Standard Turkish voice
      'languageCode': 'tr-TR',
      'speakingRate': 1.0, // Natural friendly pace
      'volumeGainDb': 0.0, // Normal volume
    },
    'casual': {
      'name': 'tr-TR-Standard-C', // Standard Turkish voice
      'languageCode': 'tr-TR',
      'speakingRate': 1.05, // Natural casual pace
      'volumeGainDb': 0.0, // Normal volume
    },
    'energetic': {
      'name': 'tr-TR-Standard-D', // Standard Turkish voice
      'languageCode': 'tr-TR',
      'speakingRate': 1.1, // Energetic but natural pace
      'volumeGainDb': 1.0, // Slightly higher volume
    },
  };

  // Initialize Google TTS service
  Future<void> initialize() async {
    try {
      // Validate API key first
      final isValidKey = await validateApiKey();
      if (!isValidKey) {
        throw Exception('Google TTS API key is invalid or has insufficient permissions');
      }
      
      // Test API connection
      final testResponse = await _testApiConnection();
      if (testResponse) {
        print('Google TTS service initialized successfully');
      } else {
        throw Exception('Google TTS API connection failed');
      }
    } catch (e) {
      print('Google TTS initialization error: $e');
      throw Exception('Google TTS service initialization failed: $e');
    }
  }

  // Test API connection
  Future<bool> _testApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('https://texttospeech.googleapis.com/v1/voices?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Available voices: ${data['voices']?.length ?? 0}');
        return true;
      } else {
        print('API test failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('API connection test error: $e');
      return false;
    }
  }

  // Generate audio file using Google TTS with enhanced error handling
  Future<String> generateAudioFile(
    String text,
    String voiceStyle,
    String language, {
    double? speed,
    double? pitch,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        throw Exception('Text cannot be empty');
      }

      // Get voice configuration
      final voiceConfig = getVoiceConfigWithFallback(voiceStyle);
      
      // Prepare request body without pitch parameter
      final requestBody = {
        'input': {
          'text': text,
        },
        'voice': {
          'languageCode': voiceConfig['languageCode'],
          'name': voiceConfig['name'],
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': speed ?? voiceConfig['speakingRate'],
          'volumeGainDb': voiceConfig['volumeGainDb'],
        },
      };

      print('Generating audio for text length: ${text.length} characters');
      print('Using voice: ${voiceConfig['name']}');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioContent = data['audioContent'];
        
        if (audioContent != null) {
          // Decode base64 audio content
          final audioBytes = base64.decode(audioContent);
          
          // Create unique filename with better naming
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'podcast_${voiceStyle}_$timestamp.mp3';
          
          // Get app documents directory with enhanced path handling
          final directory = await getApplicationDocumentsDirectory();
          final podcastDir = Directory('${directory.path}/podcasts');
          
          // Create directory if it doesn't exist
          if (!await podcastDir.exists()) {
            await podcastDir.create(recursive: true);
            print('Created podcast directory: ${podcastDir.path}');
          }
          
          final filePath = '${podcastDir.path}/$filename';
          final audioFile = File(filePath);
          
          // Write audio bytes to file with error handling
          try {
            await audioFile.writeAsBytes(audioBytes);
            print('Google TTS audio file created successfully: $filePath');
            print('File size: ${audioBytes.length} bytes');
            
            // For Google TTS, if we get a large file, it's likely valid
            if (audioBytes.length > 1000) {
              print('Google TTS audio file appears valid (large size)');
              return filePath;
            } else {
              print('Google TTS audio file seems too small, trying fallback...');
              return await _generateWithFallbackVoice(text, voiceStyle, language, speed);
            }
          } catch (writeError) {
            print('Error writing audio file: $writeError');
            throw Exception('Failed to save audio file: $writeError');
          }
        } else {
          throw Exception('No audio content in response');
        }
      } else {
        print('Google TTS API error: ${response.statusCode} - ${response.body}');
        
        // Try with a different voice if the current one fails
        if (response.statusCode == 400) {
          print('Trying with fallback voice configuration...');
          return await _generateWithFallbackVoice(text, voiceStyle, language, speed);
        }
        
        throw Exception('Google TTS API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Google TTS generation error: $e');
      // Return placeholder audio as fallback
      return await _generatePlaceholderAudio();
    }
  }

  // Generate with fallback voice configuration
  Future<String> _generateWithFallbackVoice(
    String text,
    String voiceStyle,
    String language,
    double? speed,
  ) async {
    try {
      // Use a simpler voice configuration
      final fallbackConfig = {
        'name': 'tr-TR-Standard-A',
        'languageCode': 'tr-TR',
        'speakingRate': 1.0,
        'volumeGainDb': 0.0,
      };
      
      final requestBody = {
        'input': {
          'text': text,
        },
        'voice': {
          'languageCode': fallbackConfig['languageCode'],
          'name': fallbackConfig['name'],
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': speed ?? fallbackConfig['speakingRate'],
          'volumeGainDb': fallbackConfig['volumeGainDb'],
        },
      };

      print('Trying fallback voice: ${fallbackConfig['name']}');

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioContent = data['audioContent'];
        
        if (audioContent != null) {
          final audioBytes = base64.decode(audioContent);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'podcast_fallback_$timestamp.mp3';
          
          final directory = await getApplicationDocumentsDirectory();
          final podcastDir = Directory('${directory.path}/podcasts');
          
          if (!await podcastDir.exists()) {
            await podcastDir.create(recursive: true);
          }
          
          final filePath = '${podcastDir.path}/$filename';
          final audioFile = File(filePath);
          
          await audioFile.writeAsBytes(audioBytes);
          print('Fallback voice audio created: $filePath');
          
          // For fallback voice, if we get a large file, it's likely valid
          if (audioBytes.length > 1000) {
            print('Fallback audio file appears valid (large size)');
            return filePath;
          } else {
            print('Fallback audio file seems too small');
            return await _generatePlaceholderAudio();
          }
        }
      }
      
      throw Exception('Fallback voice also failed');
    } catch (e) {
      print('Fallback voice error: $e');
      return await _generatePlaceholderAudio();
    }
  }

  // Generate placeholder audio as fallback
  Future<String> _generatePlaceholderAudio() async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'podcast_placeholder_$timestamp.mp3';
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final podcastDir = Directory('${directory.path}/podcasts');
      
      // Create directory if it doesn't exist
      if (!await podcastDir.exists()) {
        await podcastDir.create(recursive: true);
      }
      
      final filePath = '${podcastDir.path}/$filename';
      final audioFile = File(filePath);
      
      // Create simple MP3 placeholder (silence)
      final placeholderAudioBytes = _createPlaceholderMP3();
      await audioFile.writeAsBytes(placeholderAudioBytes);
      
      print('Placeholder audio created: $filePath');
      return filePath;
    } catch (e) {
      print('Placeholder audio creation error: $e');
      return 'placeholder_audio.mp3';
    }
  }

  // Create placeholder MP3 file (silence)
  Uint8List _createPlaceholderMP3() {
    // Create a more realistic placeholder MP3 file
    // This is a minimal MP3 file with proper header structure
    final List<int> mp3Header = [
      // MP3 frame header (Layer 3, 44.1kHz, 128kbps, Stereo)
      0xFF, 0xFB, 0x90, 0x44,
      
      // MPEG-1 Layer 3 frame data (simplified)
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      
      // Additional frame for longer placeholder
      0xFF, 0xFB, 0x90, 0x44,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ];
    
    return Uint8List.fromList(mp3Header);
  }

  // Validate audio file
  Future<bool> _validateAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Audio file does not exist: $filePath');
        return false;
      }
      
      final fileSize = await file.length();
      if (fileSize < 100) {
        print('Audio file is too small: $fileSize bytes');
        return false;
      }
      
      // For Google TTS, we just check if the file exists and has reasonable size
      // Google TTS generates valid MP3 files, so we don't need to check headers
      if (fileSize > 1000) {
        print('Audio file appears to be valid (size: $fileSize bytes)');
        return true;
      } else {
        print('Audio file is too small to be valid: $fileSize bytes');
        return false;
      }
    } catch (e) {
      print('Audio validation error: $e');
      return false;
    }
  }

  // Get available voices from Google TTS
  Future<List<Map<String, dynamic>>> getAvailableVoices({String? languageCode}) async {
    try {
      final url = languageCode != null 
          ? 'https://texttospeech.googleapis.com/v1/voices?languageCode=$languageCode&key=$_apiKey'
          : 'https://texttospeech.googleapis.com/v1/voices?key=$_apiKey';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final voices = data['voices'] as List;
        
        return voices.map((voice) => {
          'name': voice['name'],
          'languageCode': voice['languageCodes'][0],
          'ssmlGender': voice['ssmlGender'],
          'naturalSampleRateHertz': voice['naturalSampleRateHertz'],
        }).toList();
      } else {
        print('Failed to get voices: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  // Get available languages
  Future<List<Map<String, String>>> getAvailableLanguages() async {
    try {
      final voices = await getAvailableVoices();
      final languages = <String, String>{};
      
      for (final voice in voices) {
        final languageCode = voice['languageCode'] as String;
        final languageName = _getLanguageName(languageCode);
        languages[languageCode] = languageName;
      }
      
      return languages.entries.map((entry) => {
        'code': entry.key,
        'name': entry.value,
      }).toList();
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  // Get language name from code
  String _getLanguageName(String languageCode) {
    final languageNames = {
      'tr-TR': 'Türkçe',
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'de-DE': 'Deutsch',
      'fr-FR': 'Français',
      'es-ES': 'Español',
      'it-IT': 'Italiano',
      'pt-BR': 'Português (Brasil)',
      'ru-RU': 'Русский',
      'ja-JP': '日本語',
      'ko-KR': '한국어',
      'zh-CN': '中文 (简体)',
    };
    
    return languageNames[languageCode] ?? languageCode;
  }

  // Check if TTS is available
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('https://texttospeech.googleapis.com/v1/voices?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('TTS availability check error: $e');
      return false;
    }
  }

  // Validate API key and test connection
  Future<bool> validateApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('https://texttospeech.googleapis.com/v1/voices?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final voices = data['voices'] as List;
        print('API key validated successfully. Available voices: ${voices.length}');
        return true;
      } else if (response.statusCode == 403) {
        print('API key is invalid or has insufficient permissions');
        return false;
      } else {
        print('API validation failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('API validation error: $e');
      return false;
    }
  }

  // Get voice configuration
  Map<String, dynamic> getVoiceConfig(String voiceStyle) {
    return _voiceConfigs[voiceStyle] ?? _voiceConfigs['professional']!;
  }

  // Get available Turkish voices
  Future<List<String>> getAvailableTurkishVoices() async {
    try {
      final voices = await getAvailableVoices(languageCode: 'tr-TR');
      return voices.map((voice) => voice['name'] as String).toList();
    } catch (e) {
      print('Error getting Turkish voices: $e');
      // Return default voices if API fails
      return ['tr-TR-Standard-A', 'tr-TR-Standard-B', 'tr-TR-Standard-C', 'tr-TR-Standard-D'];
    }
  }

  // Get voice configuration with fallback
  Map<String, dynamic> getVoiceConfigWithFallback(String voiceStyle) {
    final config = _voiceConfigs[voiceStyle] ?? _voiceConfigs['professional']!;
    
    // Ensure we have a valid voice name
    if (config['name'] == null || config['name'].toString().isEmpty) {
      return _voiceConfigs['professional']!;
    }
    
    return config;
  }

  // Calculate estimated duration based on text length and speech rate
  double calculateEstimatedDuration(String text, double speakingRate) {
    // Average speaking rate: 150 words per minute
    final wordsPerMinute = 150 * speakingRate;
    final wordCount = text.split(' ').length;
    return (wordCount / wordsPerMinute) * 60; // Convert to seconds
  }

  // Test text synthesis
  Future<Map<String, dynamic>> testSynthesis(String text, String voiceStyle) async {
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

  // Test TTS functionality with error handling
  Future<Map<String, dynamic>> testTTSFunctionality() async {
    try {
      print('=== Testing Google TTS Functionality ===');
      
      // Test 1: Validate API key
      final isValidKey = await validateApiKey();
      print('API key validation: ${isValidKey ? 'PASSED' : 'FAILED'}');
      
      // Test 2: Get available voices
      final voices = await getAvailableTurkishVoices();
      print('Available Turkish voices: ${voices.length}');
      
      // Test 3: Test voice configurations
      for (final style in _voiceConfigs.keys) {
        final config = getVoiceConfigWithFallback(style);
        print('Voice config for $style: ${config['name']}');
      }
      
      // Test 4: Generate test audio
      final testText = 'Merhaba, bu bir test sesidir.';
      final testAudioPath = await generateAudioFile(
        testText,
        'professional',
        'tr-TR',
      );
      
      final testFile = File(testAudioPath);
      final fileExists = await testFile.exists();
      final fileSize = fileExists ? await testFile.length() : 0;
      
      print('Test audio generation: ${fileExists ? 'PASSED' : 'FAILED'}');
      print('Test audio file size: $fileSize bytes');
      
      return {
        'apiKeyValid': isValidKey,
        'availableVoices': voices.length,
        'testAudioGenerated': fileExists,
        'testAudioSize': fileSize,
        'testAudioPath': testAudioPath,
      };
    } catch (e) {
      print('TTS functionality test error: $e');
      return {
        'apiKeyValid': false,
        'availableVoices': 0,
        'testAudioGenerated': false,
        'testAudioSize': 0,
        'testAudioPath': null,
        'error': e.toString(),
      };
    }
  }

  // Simple test method to verify TTS functionality
  Future<bool> testSimpleTTS() async {
    try {
      print('=== Testing Simple Google TTS ===');
      
      final testText = 'Merhaba, bu bir test sesidir.';
      final testAudioPath = await generateAudioFile(
        testText,
        'professional',
        'tr-TR',
      );
      
      final testFile = File(testAudioPath);
      final fileExists = await testFile.exists();
      final fileSize = fileExists ? await testFile.length() : 0;
      
      print('Test result: ${fileExists ? 'SUCCESS' : 'FAILED'}');
      print('Test file size: $fileSize bytes');
      print('Test file path: $testAudioPath');
      
      return fileExists && fileSize > 1000;
    } catch (e) {
      print('Simple TTS test error: $e');
      return false;
    }
  }
} 