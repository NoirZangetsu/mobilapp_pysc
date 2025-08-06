import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/env_config.dart';

class GoogleTTSService {
  static GoogleTTSService? _instance;
  static GoogleTTSService get instance => _instance ??= GoogleTTSService._();
  
  GoogleTTSService._();
  
  // API configuration
  static const String _baseUrl = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  static String get _apiKey => EnvConfig.getGoogleTtsApiKey();
  
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
            
            // Check if audio file was created and has reasonable size
            final file = File(filePath);
            if (await file.exists()) {
              final fileSize = await file.length();
              print('Google TTS audio file created: $filePath, size: $fileSize bytes');
              
              if (fileSize > 1000) { // Minimum file size check
                return filePath;
              } else {
                throw Exception('Generated audio file is too small: $fileSize bytes');
              }
            } else {
              throw Exception('Google TTS failed to create audio file');
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
        throw Exception('Google TTS API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Google TTS generation error: $e');
      rethrow;
    }
  }

  // Get voice configuration
  Map<String, dynamic> getVoiceConfig(String voiceStyle) {
    return _voiceConfigs[voiceStyle] ?? _voiceConfigs['professional']!;
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