import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/podcast.dart';
import '../models/document.dart';
import 'gemini_service.dart';
import 'tts_service.dart';

class PodcastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();
  final TTSService _ttsService = TTSService();

  // Enhanced podcast types
  static const Map<String, Map<String, dynamic>> _podcastTypes = {
    'educational': {
      'name': 'Eğitim',
      'description': 'Öğretici ve bilgilendirici içerik',
      'structure': ['Giriş', 'Ana Konu', 'Örnekler', 'Özet', 'Kapanış'],
      'tone': 'professional',
    },
    'story': {
      'name': 'Hikaye',
      'description': 'Narrative ve hikaye anlatımı',
      'structure': ['Giriş', 'Karakterler', 'Olay Örgüsü', 'Sonuç', 'Kapanış'],
      'tone': 'friendly',
    },
    'news': {
      'name': 'Haber',
      'description': 'Güncel olaylar ve haberler',
      'structure': ['Giriş', 'Ana Haber', 'Detaylar', 'Analiz', 'Kapanış'],
      'tone': 'professional',
    },
    'interview': {
      'name': 'Röportaj',
      'description': 'Soru-cevap formatında içerik',
      'structure': ['Giriş', 'Konuk Tanıtımı', 'Sorular', 'Cevaplar', 'Kapanış'],
      'tone': 'casual',
    },
  };

  // Enhanced podcast creation with better error handling
  Future<Podcast> createPodcastFromTopic(
    String userId,
    String topic,
    String title,
    {String voiceStyle = 'professional', String language = 'tr-TR', int duration = 5, String podcastType = 'educational'}
  ) async {
    try {
      print('=== Starting podcast creation ===');
      print('User ID: $userId');
      print('Topic: $topic');
      print('Title: $title');
      print('Voice Style: $voiceStyle');
      print('Language: $language');
      print('Duration: $duration minutes');
      print('Podcast Type: $podcastType');

      // Validate inputs
      if (topic.trim().isEmpty) {
        throw Exception('Topic cannot be empty');
      }

      // Get podcast type configuration
      final typeConfig = _podcastTypes[podcastType] ?? _podcastTypes['educational']!;
      print('Using podcast type config: ${typeConfig['name']}');
      
      // Generate podcast content with enhanced error handling
      print('Generating podcast content...');
      final podcastData = await _generatePodcastContent(
        topic,
        title,
        typeConfig,
        duration,
        voiceStyle,
        language,
      );

      // Validate generated content
      if (podcastData['script'] == null || podcastData['script'].toString().isEmpty) {
        throw Exception('Failed to generate podcast script');
      }

      print('Content generated successfully');
      print('Script length: ${podcastData['script'].toString().length} characters');

      // Generate audio from script
      print('Generating audio from script...');
      final audioUrl = await _uploadAudioToStorage(
        podcastData['script'],
        voiceStyle,
        language,
      );

      print('Audio generated successfully: $audioUrl');

      // Create podcast object with calculated duration
      final estimatedDuration = Duration(minutes: duration); // Use requested duration
      
      final podcast = Podcast(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: podcastData['title'] ?? title, // Use AI generated title if available
        description: podcastData['description'] ?? '$topic konusu hakkında oluşturulan podcast',
        sourceType: 'topic',
        sourceId: topic,
        audioUrl: audioUrl,
        duration: estimatedDuration, // Use requested duration
        createdAt: DateTime.now(),
        voiceStyle: voiceStyle,
        language: language,
        podcastType: podcastType,
        script: podcastData['script'], // Save script for reference
      );

      print('Podcast object created with ID: ${podcast.id}');
      print('Final title: ${podcast.title}');
      print('Final description: ${podcast.description}');
      print('Duration: ${estimatedDuration.inMinutes} minutes');
      print('Script saved: ${podcast.script?.length ?? 0} characters');

      // Save to Firestore with error handling
      try {
        print('Saving podcast to Firestore...');
        await _savePodcast(podcast);
        print('Podcast saved successfully: ${podcast.title}');
        print('=== Podcast creation completed successfully ===');
        return podcast;
      } catch (saveError) {
        print('Failed to save podcast to Firestore: $saveError');
        print('Returning podcast object without saving to database');
        // Return podcast object even if save fails
        return podcast;
      }
    } catch (e) {
      print('=== Podcast creation failed ===');
      print('Error: $e');
      rethrow;
    }
  }

  // Enhanced content generation with better JSON handling
  Future<Map<String, dynamic>> _generatePodcastContent(
    String topic,
    String title,
    Map<String, dynamic> typeConfig,
    int duration,
    String voiceStyle,
    String language,
  ) async {
    try {
      // Create enhanced prompt for more natural speech
      final prompt = '''
Create a natural, conversational podcast about "$topic" with the title "$title".

Requirements:
- Duration: ${duration} minutes
- Type: ${typeConfig['name']}
- Structure: ${typeConfig['structure'].join(', ')}
- Tone: ${typeConfig['tone']}
- Language: $language

CRITICAL GUIDELINES FOR NATURAL SPEECH:
1. Write in SHORT, SIMPLE sentences - maximum 15-20 words per sentence
2. Use natural Turkish speech patterns and everyday language
3. Include natural pauses with commas and periods
4. Avoid complex technical terms - explain in simple words
5. Use conversational transitions: "Şimdi", "Sonra", "Ayrıca", "Özellikle"
6. Include natural speech fillers: "Yani", "Aslında", "Tabii ki"
7. Break long thoughts into multiple short sentences
8. Use active voice and direct address: "Siz de", "Hepimiz"
9. Include natural breathing pauses every 2-3 sentences
10. Make it sound like a real person talking, not reading

SPEECH OPTIMIZATION:
- Each sentence should be easy to pronounce
- Use common Turkish words, not formal language
- Include natural rhythm and flow
- Add emotional expressions: "Harika", "İlginç", "Önemli"
- Use repetition for emphasis: "Çok önemli", "Gerçekten önemli"

IMPORTANT: Return ONLY valid JSON format, no extra text:

{
  "title": "Podcast Title",
  "description": "Brief description of the podcast",
  "script": "Natural, conversational script optimized for speech with short sentences and natural flow"
}

Make sure the script is engaging, educational, and sounds completely natural when spoken.
''';

      // Generate content using Gemini
      final response = await _geminiService.generateResponse(prompt, []);
      
      // Enhanced JSON parsing with error handling
      Map<String, dynamic> podcastData;
      
      try {
        // Clean the response first
        String cleanedResponse = response.trim();
        
        print('Original response: $response');
        
        // Remove markdown code blocks if present
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        }
        if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }
        if (cleanedResponse.endsWith('```')) {
          cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
        }
        
        // Remove bullet points and special characters
        cleanedResponse = cleanedResponse
            .replaceAll(RegExp(r'^[•\-\*]\s*'), '') // Remove leading bullets
            .replaceAll(RegExp(r'\n[•\-\*]\s*'), '\n') // Remove bullet points in text
            .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control characters
            .replaceAll(RegExp(r'\\n'), '\n') // Fix newlines
            .replaceAll(RegExp(r'\\"'), '"') // Fix quotes
            .trim();
        
        // Fix common JSON formatting issues
        cleanedResponse = cleanedResponse
            .replaceAll(RegExp(r'```json\s*'), '') // Remove any remaining ```json
            .replaceAll(RegExp(r'```\s*'), '') // Remove any remaining ```
            .trim();
        
        // Ensure the response starts with {
        if (!cleanedResponse.startsWith('{')) {
          // Find the first { character
          final jsonStart = cleanedResponse.indexOf('{');
          if (jsonStart != -1) {
            cleanedResponse = cleanedResponse.substring(jsonStart);
          } else {
            throw Exception('JSON formatı bulunamadı');
          }
        }
        
        // Ensure the response ends with }
        if (!cleanedResponse.endsWith('}')) {
          // Find the last } character
          final jsonEnd = cleanedResponse.lastIndexOf('}');
          if (jsonEnd != -1) {
            cleanedResponse = cleanedResponse.substring(0, jsonEnd + 1);
          }
        }
        
        // Additional cleaning for control characters and formatting
        cleanedResponse = cleanedResponse
            .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove ALL control characters
            .replaceAll(RegExp(r'\\n'), '\n') // Fix escaped newlines
            .replaceAll(RegExp(r'\\"'), '"') // Fix escaped quotes
            .replaceAll(RegExp(r'\\t'), '\t') // Fix tabs
            .replaceAll(RegExp(r'\\r'), '\r') // Fix carriage returns
            .replaceAll(RegExp(r'\\'), '\\\\') // Fix backslashes
            .trim();
        
        print('Cleaned response: $cleanedResponse');
        
        // Try to parse as JSON
        podcastData = json.decode(cleanedResponse) as Map<String, dynamic>;
        print('Content generated successfully');
        print('Title: ${podcastData['title']}');
        print('Description: ${podcastData['description']}');
        print('Script length: ${podcastData['script']?.toString().length ?? 0} characters');
      } catch (jsonError) {
        print('JSON parsing error: $jsonError');
        print('Original response: $response');
        
        // If JSON parsing fails, try to extract content manually
        podcastData = _extractContentFromText(response, topic, title);
      }

      // Validate extracted data
      if (podcastData['script'] == null || podcastData['script'].toString().isEmpty) {
        // Generate fallback content
        podcastData = _generateFallbackContent(topic, title, typeConfig);
      }

      return podcastData;
    } catch (e) {
      print('Content generation error: $e');
      // Return fallback content
      return _generateFallbackContent(topic, title, typeConfig);
    }
  }

  // Extract content from text response when JSON parsing fails
  Map<String, dynamic> _extractContentFromText(String response, String topic, String title) {
    try {
      // Try to find JSON-like structure in the response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd + 1);
        
        // Clean the extracted JSON string
        String cleanedJson = jsonString
            .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // Remove control characters
            .replaceAll(RegExp(r'\\n'), '\n') // Fix newlines
            .replaceAll(RegExp(r'\\"'), '"') // Fix quotes
            .replaceAll(RegExp(r'\\t'), '\t') // Fix tabs
            .replaceAll(RegExp(r'\\r'), '\r') // Fix carriage returns
            .replaceAll(RegExp(r'\\'), '\\\\') // Fix backslashes
            .trim();
        
        print('Extracted JSON string: $cleanedJson');
        
        try {
          return json.decode(cleanedJson) as Map<String, dynamic>;
        } catch (e) {
          print('Extracted JSON parsing failed: $e');
        }
      }
      
      // If no JSON found or parsing failed, create content from the text
      return {
        'title': title.isNotEmpty ? title : 'Podcast about $topic',
        'description': 'Generated podcast about $topic',
        'script': response.trim(),
      };
    } catch (e) {
      print('Content extraction error: $e');
      return _generateFallbackContent(topic, title, _podcastTypes['educational']!);
    }
  }

  // Generate fallback content when all else fails
  Map<String, dynamic> _generateFallbackContent(String topic, String title, Map<String, dynamic> typeConfig) {
    final fallbackScript = '''
Merhaba! Bugün $topic hakkında konuşacağız.

Bu konu gerçekten çok önemli. Hepimiz bu konuyu anlamalıyız.

Şimdi size bu konuyu açıklayacağım. Çok basit ve anlaşılır olacak.

Önce temel bilgileri verelim. Sonra detaylara geçeriz.

Bu konu hayatımızda çok yer tutuyor. Yani gerçekten önemli.

Ayrıca bu bilgiyi günlük hayatta kullanabiliriz. Çok pratik.

Son olarak, bu konuyu unutmayın. Gerçekten değerli.

Bu podcast'in sonuna geldik. Umarım faydalı olmuştur.

Tekrar görüşmek üzere!
''';

    return {
      'title': title.isNotEmpty ? title : 'Podcast about $topic',
      'description': 'Generated podcast about $topic',
      'script': fallbackScript,
    };
  }

  // Create podcast from document
  Future<Podcast> createPodcastFromDocument(
    String userId,
    Document document,
    String title,
    {String voiceStyle = 'professional', String language = 'tr-TR'}
  ) async {
    try {
      // Get document content
      final documentContent = document.content ?? '';
      
      if (documentContent.isEmpty) {
        throw Exception('Document content is empty');
      }

      final prompt = '''
Aşağıdaki doküman içeriğinden bir podcast senaryosu oluştur.

Doküman: ${document.fileName}
İçerik: $documentContent

Senaryo şu bölümleri içermeli:
1. Giriş (30-45 saniye)
2. Ana içerik (3-8 dakika - içeriğe göre değişir)
3. Özet ve kapanış (30-45 saniye)

Ses tonu: $voiceStyle
Dil: $language

ÖNEMLİ: Sadece aşağıdaki JSON formatında yanıt ver, başka hiçbir metin ekleme:

{
  "title": "Podcast başlığı",
  "description": "Podcast açıklaması (2-3 cümle)",
  "script": "Sesli okunacak metin (giriş + ana içerik + kapanış)",
  "estimatedDuration": 300,
  "segments": [
    {
      "name": "Giriş",
      "duration": 30,
      "text": "Giriş metni"
    },
    {
      "name": "Ana İçerik",
      "duration": 240,
      "text": "Ana içerik metni"
    },
    {
      "name": "Kapanış",
      "duration": 30,
      "text": "Kapanış metni"
    }
  ]
}
''';

      final response = await _geminiService.generateResponse(prompt, []);
      final podcastData = _parsePodcastFromResponse(response);
      
      // Calculate total duration from segments
      int totalDuration = 0;
      if (podcastData.containsKey('segments')) {
        final segments = podcastData['segments'] as List;
        for (var segment in segments) {
          totalDuration += segment['duration'] as int;
        }
      } else {
        totalDuration = podcastData['estimatedDuration'] ?? 300;
      }
      
      // Generate audio from script
      final audioUrl = await _uploadAudioToStorage(
        podcastData['script'],
        voiceStyle,
        language,
      );
      
      final podcastId = DateTime.now().millisecondsSinceEpoch.toString();
      final podcast = Podcast(
        id: podcastId,
        userId: userId,
        title: podcastData['title'] ?? title,
        description: podcastData['description'],
        sourceType: 'document',
        sourceId: document.id,
        audioUrl: audioUrl,
        duration: Duration(seconds: totalDuration),
        createdAt: DateTime.now(),
        voiceStyle: voiceStyle,
        language: language,
      );

      await _savePodcast(podcast);
      return podcast;
    } catch (e) {
      throw Exception('Podcast oluşturma başarısız: $e');
    }
  }

  // Parse podcast data from AI response
  Map<String, dynamic> _parsePodcastFromResponse(String response) {
    try {
      // Clean the response - remove markdown formatting and control characters
      String cleanedResponse = response
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'\s*```'), '')
          .replaceAll(RegExp(r'•'), '')
          .replaceAll(RegExp(r'\n\s*\n'), '\n')
          .trim();
      
      // Find JSON object
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('JSON formatı bulunamadı');
      }
      
      final jsonString = cleanedResponse.substring(jsonStart, jsonEnd);
      
      // Remove any control characters that might cause parsing issues
      final sanitizedJson = jsonString
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .replaceAll(RegExp(r'\\n'), '\n')
          .replaceAll(RegExp(r'\\"'), '"');
      
      final parsedData = json.decode(sanitizedJson) as Map<String, dynamic>;
      
      // Validate required fields
      if (!parsedData.containsKey('title') || !parsedData.containsKey('script')) {
        throw Exception('Gerekli alanlar eksik');
      }
      
      return parsedData;
    } catch (e) {
      print('JSON parsing error: $e');
      print('Original response: $response');
      
      // Fallback: create basic podcast data
      return {
        'title': 'Podcast',
        'description': 'AI tarafından oluşturulan podcast',
        'script': 'Bu bir örnek podcast metnidir. İçerik yüklenirken bir hata oluştu.',
        'estimatedDuration': 300,
        'segments': [
          {
            'name': 'Giriş',
            'duration': 30,
            'text': 'Merhaba, bu podcast bölümüne hoş geldiniz.'
          },
          {
            'name': 'Ana İçerik',
            'duration': 240,
            'text': 'Bu bölümde konu hakkında detaylı bilgi verilecektir.'
          },
          {
            'name': 'Kapanış',
            'duration': 30,
            'text': 'Dinlediğiniz için teşekkürler.'
          }
        ]
      };
    }
  }

  // Enhanced TTS configuration
  static const Map<String, Map<String, dynamic>> _voiceConfigs = {
    'professional': {
      'provider': 'google',
      'voice': 'tr-TR-Standard-A',
      'speed': 1.0,
    },
    'friendly': {
      'provider': 'google',
      'voice': 'tr-TR-Standard-B',
      'speed': 1.1,
    },
    'casual': {
      'provider': 'google',
      'voice': 'tr-TR-Standard-C',
      'speed': 1.2,
    },
    'energetic': {
      'provider': 'google',
      'voice': 'tr-TR-Standard-D',
      'speed': 1.3,
    },
  };

  // Upload audio to local storage instead of Firebase Storage
  Future<String> _uploadAudioToStorage(
    String script,
    String voiceStyle,
    String language,
  ) async {
    try {
      // Initialize TTS service
      await _ttsService.initialize();
      
      // Check if TTS is available
      final isAvailable = await _ttsService.isAvailable();
      if (!isAvailable) {
        print('TTS not available, using placeholder audio');
        return await _generatePlaceholderAudio();
      }
      
      // Generate audio with enhanced settings
      final audioFilePath = await _ttsService.generateAudioFile(
        script,
        voiceStyle,
        language,
      );
      
      print('TTS generated audio file: $audioFilePath');
      
      // Save to local storage instead of Firebase Storage
      try {
        final audioFile = File(audioFilePath);
        if (await audioFile.exists()) {
          // Create a unique filename for local storage
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'podcast_${voiceStyle}_$timestamp.mp3';
          
          // Get app documents directory
          final directory = await getApplicationDocumentsDirectory();
          final podcastDir = Directory('${directory.path}/podcasts');
          
          // Create directory if it doesn't exist
          if (!await podcastDir.exists()) {
            await podcastDir.create(recursive: true);
            print('Created podcast directory: ${podcastDir.path}');
          }
          
          // Copy file to local storage with unique name
          final localFilePath = '${podcastDir.path}/$filename';
          final localFile = File(localFilePath);
          
          await audioFile.copy(localFilePath);
          print('Audio saved to local storage: $localFilePath');
          print('File size: ${await localFile.length()} bytes');
          print('File exists: ${await localFile.exists()}');
          
          return localFilePath;
        } else {
          print('Audio file not found at path: $audioFilePath');
          return await _generatePlaceholderAudio();
        }
      } catch (localError) {
        print('Local storage error: $localError');
        
        // Try to create a local backup
        try {
          final localBackupPath = await _createLocalBackup(audioFilePath);
          return localBackupPath;
        } catch (backupError) {
          print('Local backup creation failed: $backupError');
          return await _generatePlaceholderAudio();
        }
      }
    } catch (e) {
      print('Audio generation error: $e');
      // Return a placeholder URL if generation fails
      return await _generatePlaceholderAudio();
    }
  }

  // Create local backup of audio file
  Future<String> _createLocalBackup(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      if (await originalFile.exists()) {
        final directory = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${directory.path}/podcasts/backup');
        
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupPath = '${backupDir.path}/backup_$timestamp.mp3';
        final backupFile = File(backupPath);
        
        await originalFile.copy(backupPath);
        print('Local backup created: $backupPath');
        return backupPath;
      } else {
        throw Exception('Original file not found');
      }
    } catch (e) {
      print('Backup creation error: $e');
      rethrow;
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
      
      // Create local file path
      final localFilePath = '${podcastDir.path}/$filename';
      final localFile = File(localFilePath);
      
      // Create placeholder audio file
      final placeholderAudioBytes = _createPlaceholderAudio();
      await localFile.writeAsBytes(placeholderAudioBytes);
      
      print('Placeholder audio created locally: $localFilePath');
      return localFilePath;
    } catch (e) {
      print('Placeholder audio creation error: $e');
      return 'placeholder_audio.mp3';
    }
  }

  // Create local audio file as fallback
  Future<File> _createLocalAudioFile(String filename, Uint8List audioData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/podcasts/$filename');
    
    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);
    
    // Write audio data to file
    await file.writeAsBytes(audioData);
    return file;
  }

  // Create placeholder audio file (WAV format)
  Uint8List _createPlaceholderAudio() {
    // Simple WAV file header for 1 second of silence
    final List<int> wavHeader = [
      0x52, 0x49, 0x46, 0x46, // RIFF
      0x24, 0x00, 0x00, 0x00, // File size - 36 bytes
      0x57, 0x41, 0x56, 0x45, // WAVE
      0x66, 0x6D, 0x74, 0x20, // fmt chunk
      0x10, 0x00, 0x00, 0x00, // fmt chunk size
      0x01, 0x00, // Audio format (PCM)
      0x01, 0x00, // Channels (mono)
      0x44, 0xAC, 0x00, 0x00, // Sample rate (44100)
      0x88, 0x58, 0x01, 0x00, // Byte rate
      0x02, 0x00, // Block align
      0x10, 0x00, // Bits per sample
      0x64, 0x61, 0x74, 0x61, // data chunk
      0x00, 0x00, 0x00, 0x00, // data chunk size
    ];
    
    return Uint8List.fromList(wavHeader);
  }

  // Save podcast to Firestore with enhanced error handling
  Future<void> _savePodcast(Podcast podcast) async {
    try {
      // First, ensure the user document exists
      await _firestore
          .collection('users')
          .doc(podcast.userId)
          .set({
        'createdAt': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      // Then save the podcast
      await _firestore
          .collection('users')
          .doc(podcast.userId)
          .collection('podcasts')
          .doc(podcast.id)
          .set(podcast.toMap());
          
      print('Podcast saved successfully to Firestore: ${podcast.title}');
    } catch (e) {
      print('Failed to save podcast to Firestore: $e');
      
      // If Firestore save fails, try to save locally
      try {
        await _savePodcastLocally(podcast);
        print('Podcast saved locally as backup');
      } catch (localError) {
        print('Local save also failed: $localError');
        throw Exception('Podcast kaydetme hatası: $e');
      }
    }
  }
  
  // Save podcast locally as backup
  Future<void> _savePodcastLocally(Podcast podcast) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final podcastsDir = Directory('${directory.path}/podcasts');
      
      if (!await podcastsDir.exists()) {
        await podcastsDir.create(recursive: true);
      }
      
      final podcastFile = File('${podcastsDir.path}/${podcast.id}.json');
      await podcastFile.writeAsString(json.encode(podcast.toMap()));
    } catch (e) {
      print('Local save error: $e');
      rethrow;
    }
  }

  // Get user's podcasts
  Stream<List<Podcast>> getUserPodcasts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('podcasts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Podcast.fromMap(doc.data()))
          .toList();
    });
  }

  // Get specific podcast
  Future<Podcast?> getPodcast(String userId, String podcastId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcasts')
          .doc(podcastId)
          .get();
      
      if (doc.exists) {
        return Podcast.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Podcast getirme hatası: $e');
    }
  }

  // Update podcast listen count
  Future<void> updatePodcastListenCount(String userId, String podcastId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcasts')
          .doc(podcastId)
          .update({
        'listenCount': FieldValue.increment(1),
        'lastListened': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Podcast güncelleme hatası: $e');
    }
  }

  // Delete podcast
  Future<void> deletePodcast(String userId, String podcastId) async {
    try {
      // Get podcast to delete audio file
      final podcast = await getPodcast(userId, podcastId);
      if (podcast != null) {
        // Delete local audio file
        try {
          final audioFile = File(podcast.audioUrl);
          if (await audioFile.exists()) {
            await audioFile.delete();
            print('Local audio file deleted: ${podcast.audioUrl}');
          }
        } catch (e) {
          print('Local audio file deletion failed: $e');
        }
      }
      
      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcasts')
          .doc(podcastId)
          .delete();
    } catch (e) {
      throw Exception('Podcast silme hatası: $e');
    }
  }

  // Get user's podcast statistics
  Future<Map<String, dynamic>> getUserPodcastStats(String userId) async {
    try {
      final podcasts = await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcasts')
          .get();
      
      final podcastList = podcasts.docs
          .map((doc) => Podcast.fromMap(doc.data()))
          .toList();
      
      if (podcastList.isEmpty) {
        return {
          'totalPodcasts': 0,
          'totalDuration': 0,
          'totalListens': 0,
          'averageDuration': 0,
          'favoriteType': null,
          'favoriteVoiceStyle': null,
        };
      }
      
      // Calculate statistics
      final totalPodcasts = podcastList.length;
      final totalDuration = podcastList
          .map((p) => p.duration.inMinutes)
          .fold<int>(0, (sum, duration) => sum + duration);
      final totalListens = podcastList
          .map((p) => p.listenCount ?? 0)
          .fold<int>(0, (sum, count) => sum + count);
      final averageDuration = totalDuration / totalPodcasts;
      
      // Find favorite types
      final typeCounts = <String, int>{};
      final voiceStyleCounts = <String, int>{};
      
      for (final podcast in podcastList) {
        if (podcast.podcastType != null) {
          typeCounts[podcast.podcastType!] = (typeCounts[podcast.podcastType!] ?? 0) + 1;
        }
        if (podcast.voiceStyle != null) {
          voiceStyleCounts[podcast.voiceStyle!] = (voiceStyleCounts[podcast.voiceStyle!] ?? 0) + 1;
        }
      }
      
      final favoriteType = typeCounts.isNotEmpty 
          ? typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : null;
      final favoriteVoiceStyle = voiceStyleCounts.isNotEmpty 
          ? voiceStyleCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : null;
      
      return {
        'totalPodcasts': totalPodcasts,
        'totalDuration': totalDuration,
        'totalListens': totalListens,
        'averageDuration': averageDuration,
        'favoriteType': favoriteType,
        'favoriteVoiceStyle': favoriteVoiceStyle,
        'typeDistribution': typeCounts,
        'voiceStyleDistribution': voiceStyleCounts,
      };
    } catch (e) {
      throw Exception('İstatistik getirme hatası: $e');
    }
  }

  // Track podcast listen event
  Future<void> trackPodcastListen(String userId, String podcastId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcasts')
          .doc(podcastId)
          .update({
        'listenCount': FieldValue.increment(1),
        'lastListened': DateTime.now().toIso8601String(),
      });
      
      // Also track in analytics collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcast_analytics')
          .doc(podcastId)
          .set({
        'podcastId': podcastId,
        'listenTime': DateTime.now().toIso8601String(),
        'userId': userId,
      }, SetOptions(merge: true));
      
    } catch (e) {
      print('Listen tracking error: $e');
    }
  }
} 