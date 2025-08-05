import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../models/podcast.dart';
import '../models/document.dart';
import 'gemini_service.dart';
import 'tts_service.dart';
import 'package:just_audio/just_audio.dart';

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
    {String voiceStyle = 'professional', String language = 'tr-TR', String contentLength = 'detailed', String podcastType = 'educational'}
  ) async {
    try {
      print('=== Starting podcast creation ===');
      print('User ID: $userId');
      print('Topic: $topic');
      print('Title: $title');
      print('Voice Style: $voiceStyle');
      print('Language: $language');
      print('Content Length: $contentLength');
      print('Podcast Type: $podcastType');

      // Validate inputs
      if (topic.trim().isEmpty) {
        throw Exception('Topic cannot be empty');
      }

      // Enhanced word count calculation based on content length
      int minWords;
      int maxWords;
      
      switch (contentLength) {
        case 'summary':
          minWords = 300; // ~2-3 minutes
          maxWords = 450;
          break;
        case 'detailed':
          minWords = 750; // ~5-7 minutes
          maxWords = 1050;
          break;
        case 'comprehensive':
          minWords = 1500; // ~10-15 minutes
          maxWords = 2250;
          break;
        case 'extended':
          minWords = 2250; // ~15-20 minutes
          maxWords = 3000;
          break;
        default:
          minWords = 750;
          maxWords = 1050;
      }

      print('Word range: $minWords - $maxWords words');

      // Get podcast type configuration
      final typeConfig = _podcastTypes[podcastType] ?? _podcastTypes['educational']!;
      print('Using podcast type config: ${typeConfig['name']}');
      
      // Generate podcast content with enhanced error handling
      print('Generating podcast content...');
      final podcastData = await _generatePodcastContent(
        topic,
        title,
        typeConfig,
        minWords,
        maxWords,
        voiceStyle,
        language,
        contentLength,
      );

      // Validate generated content
      if (podcastData['script'] == null || podcastData['script'].toString().isEmpty) {
        throw Exception('Failed to generate podcast script');
      }

      print('Content generated successfully');
      print('Script length: ${podcastData['script'].toString().length} characters');

      // Generate audio from script
      print('Generating audio from script...');
      final audioResult = await _uploadAudioToStorage(
        podcastData['script'],
        voiceStyle,
        language,
      );

      print('Audio generated successfully: ${audioResult['url']}');
      print('Actual duration: ${audioResult['duration'].inSeconds} seconds');

      // Create podcast object with actual duration
      final actualDuration = audioResult['duration'] as Duration;
      
      print('=== PODCAST CREATION SUMMARY ===');
      print('Title: ${podcastData['title'] ?? title}');
      print('Description: ${podcastData['description'] ?? '$topic konusu hakkında oluşturulan podcast'}');
      print('Audio URL: ${audioResult['url']}');
      print('Duration: ${actualDuration.inMinutes}:${(actualDuration.inSeconds % 60).toString().padLeft(2, '0')} (${actualDuration.inSeconds} seconds)');
      print('Voice Style: $voiceStyle');
      print('Language: $language');
      print('Podcast Type: $podcastType');
      print('Script Length: ${podcastData['script']?.length ?? 0} characters');
      
      final podcast = Podcast(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: podcastData['title'] ?? title, // Use AI generated title if available
        description: podcastData['description'] ?? '$topic konusu hakkında oluşturulan podcast',
        sourceType: 'topic',
        sourceId: topic,
        audioUrl: audioResult['url'] as String,
        duration: actualDuration, // Use actual duration from audio file
        createdAt: DateTime.now(),
        voiceStyle: voiceStyle,
        language: language,
        podcastType: podcastType,
        script: podcastData['script'], // Save script for reference
      );

      print('Podcast object created with ID: ${podcast.id}');
      print('Final title: ${podcast.title}');
      print('Final description: ${podcast.description}');
      print('Final duration: ${podcast.duration.inMinutes}:${(podcast.duration.inSeconds % 60).toString().padLeft(2, '0')} (${podcast.duration.inSeconds} seconds)');
      print('Script saved: ${podcast.script?.length ?? 0} characters');
      print('=== END PODCAST CREATION SUMMARY ===');

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
    int minWords,
    int maxWords,
    String voiceStyle,
    String language,
    String contentLength,
  ) async {
    try {
      // Create enhanced prompt for more natural speech with length control
      final prompt = '''
Create a natural, conversational podcast about "$topic" with the title "$title".

REQUIREMENTS:
- Content Length: $contentLength ($minWords-$maxWords words)
- Type: ${typeConfig['name']}
- Structure: ${typeConfig['structure'].join(', ')}
- Tone: ${typeConfig['tone']}
- Language: $language

CONTENT LENGTH GUIDELINES:
- Summary (Özet): Brief overview, key points only, 300-450 words
- Detailed (Detaylı): Comprehensive explanation with examples, 750-1050 words
- Comprehensive (Bütün Konu): Complete coverage with deep analysis, 1500-2250 words
- Extended (Genişletilmiş): In-depth coverage with multiple perspectives, 2250-3000 words

LENGTH REQUIREMENTS:
- Script MUST be between $minWords and $maxWords words
- Each section should be proportional to the total length
- Include enough content to fill the specified word count
- Use natural speech patterns that sound conversational

CRITICAL GUIDELINES FOR NATURAL SPEECH:
1. Write in SHORT, SIMPLE sentences - maximum 15-20 words per sentence
2. Use natural Turkish speech patterns and everyday language
3. Include natural pauses with commas and periods
4. Avoid complex technical terms - explain in simple words
5. Use conversational transitions: "Şimdi", "Sonra", "Ayrıca", "Özellikle", "Bunun yanında"
6. Include natural speech fillers: "Yani", "Aslında", "Tabii ki", "Gerçekten"
7. Break long thoughts into multiple short sentences
8. Use active voice and direct address: "Siz de", "Hepimiz", "Birlikte"
9. Include natural breathing pauses every 2-3 sentences
10. Make it sound like a real person talking, not reading

SPEECH OPTIMIZATION:
- Each sentence should be easy to pronounce
- Use common Turkish words, not formal language
- Include natural rhythm and flow
- Add emotional expressions: "Harika", "İlginç", "Önemli", "Şaşırtıcı"
- Use repetition for emphasis: "Çok önemli", "Gerçekten önemli"
- Include examples and stories to make content engaging
- Add personal touches: "Benim deneyimim", "Sizin de yaşadığınız"

STRUCTURE REQUIREMENTS:
- Start with a compelling introduction (1-2 minutes worth of content)
- Develop main points with examples and explanations
- Include transitions between sections
- End with a strong conclusion and call to action
- Each section should flow naturally into the next

IMPORTANT: Return ONLY valid JSON format, no extra text:

{
  "title": "Podcast Title",
  "description": "Brief description of the podcast",
  "script": "Natural, conversational script optimized for speech with short sentences and natural flow. Must be $minWords-$maxWords words long."
}

Make sure the script is engaging, educational, sounds completely natural when spoken, and meets the word count requirements.
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
        
        // Validate script length
        final script = podcastData['script']?.toString() ?? '';
        final wordCount = script.split(' ').length;
        
        print('Content generated successfully');
        print('Title: ${podcastData['title']}');
        print('Description: ${podcastData['description']}');
        print('Script length: ${script.length} characters');
        print('Word count: $wordCount words');
        
        // Check if script meets length requirements
        if (wordCount < minWords) {
          print('Script too short ($wordCount words), regenerating with longer content...');
          // Regenerate with emphasis on length
          final extendedPrompt = '$prompt\n\nIMPORTANT: The previous response was too short. Please create a longer script with at least $minWords words.';
          final extendedResponse = await _geminiService.generateResponse(extendedPrompt, []);
          
          try {
            final extendedData = json.decode(extendedResponse.trim()) as Map<String, dynamic>;
            final extendedScript = extendedData['script']?.toString() ?? '';
            final extendedWordCount = extendedScript.split(' ').length;
            
            if (extendedWordCount >= minWords) {
              podcastData = extendedData;
              print('Extended script generated: $extendedWordCount words');
            }
          } catch (e) {
            print('Extended script generation failed: $e');
          }
        }
        
      } catch (jsonError) {
        print('JSON parsing error: $jsonError');
        print('Original response: $response');
        
        // If JSON parsing fails, try to extract content manually
        podcastData = _extractContentFromText(response, topic, title);
      }

      // Validate extracted data
      if (podcastData['script'] == null || podcastData['script'].toString().isEmpty) {
        throw Exception('Failed to generate podcast script - no valid content found');
      }

      return podcastData;
    } catch (e) {
      print('Content generation error: $e');
      rethrow;
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
      throw Exception('Failed to extract content from AI response');
    }
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
      
      // Generate audio from script
      final audioResult = await _uploadAudioToStorage(
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
        audioUrl: audioResult['url'] as String,
        duration: audioResult['duration'] as Duration,
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
      
      throw Exception('Failed to parse podcast data from AI response');
    }
  }

  // Get audio duration from file with enhanced error handling
  Future<Duration> _getAudioDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Audio file not found for duration check: $filePath');
      }

      print('Getting duration for file: $filePath');
      print('File size: ${await file.length()} bytes');

      // Use just_audio package to get duration
      final player = AudioPlayer();
      
      try {
        await player.setFilePath(filePath);
        
        // Wait a bit for the player to load the file
        await Future.delayed(const Duration(milliseconds: 500));
        
        final duration = player.duration;
        
        if (duration != null) {
          print('Audio duration extracted: ${duration.inSeconds} seconds (${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')})');
          return duration;
        } else {
          // If duration is null, try alternative method
          print('Duration is null, trying alternative method...');
          
          // Try to get duration by playing a small portion
          await player.seek(Duration.zero);
          await player.play();
          await Future.delayed(const Duration(milliseconds: 100));
          await player.pause();
          
          final alternativeDuration = player.duration;
          if (alternativeDuration != null) {
            print('Alternative duration method successful: ${alternativeDuration.inSeconds} seconds');
            return alternativeDuration;
          }
          
          throw Exception('Could not determine audio duration - both methods failed');
        }
      } finally {
        await player.dispose();
      }
    } catch (e) {
      print('Error getting audio duration: $e');
      
      // Fallback: estimate duration based on file size and bitrate
      try {
        final file = File(filePath);
        final fileSize = await file.length();
        
        // Estimate duration based on typical MP3 bitrate (128 kbps)
        // Formula: duration = file_size / (bitrate / 8)
        const bitrate = 128 * 1024; // 128 kbps in bits per second
        final estimatedSeconds = (fileSize * 8) / bitrate;
        final estimatedDuration = Duration(seconds: estimatedSeconds.round());
        
        print('Using estimated duration: ${estimatedDuration.inSeconds} seconds (based on file size)');
        return estimatedDuration;
      } catch (fallbackError) {
        print('Fallback duration estimation failed: $fallbackError');
        
        // Final fallback: return a default duration
        const defaultDuration = Duration(minutes: 5);
        print('Using default duration: ${defaultDuration.inMinutes} minutes');
        return defaultDuration;
      }
    }
  }

  // Upload audio to local storage instead of Firebase Storage
  Future<Map<String, dynamic>> _uploadAudioToStorage(
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
        throw Exception('TTS service is not available');
      }
      
      // Generate audio with duration information
      print('Generating audio with duration information...');
      final audioResult = await _ttsService.generateAudioFileWithDuration(
        script,
        voiceStyle,
        language,
      );
      
      print('TTS generated audio file: ${audioResult['filePath']}');
      print('TTS method used: ${audioResult['method']}');
      print('TTS duration: ${audioResult['duration'].inSeconds} seconds');
      
      // Verify the file exists and get its size
      final audioFile = File(audioResult['filePath']);
      if (await audioFile.exists()) {
        print('Audio file verified: ${audioResult['filePath']}');
        print('Audio file size: ${await audioFile.length()} bytes');
        print('Audio duration: ${audioResult['duration'].inMinutes}:${(audioResult['duration'].inSeconds % 60).toString().padLeft(2, '0')}');
        
        return {
          'url': audioResult['filePath'],
          'duration': audioResult['duration'],
          'method': audioResult['method'],
        };
      } else {
        throw Exception('Audio file not found at path: ${audioResult['filePath']}');
      }
    } catch (e) {
      print('Audio generation error: $e');
      rethrow;
    }
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
      throw Exception('Podcast kaydetme hatası: $e');
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
          .fold<int>(0, (total, duration) => total + duration);
      final totalListens = podcastList
          .map((p) => p.listenCount ?? 0)
          .fold<int>(0, (total, listenCount) => total + listenCount);
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

  // Validate and update podcast duration if needed
  Future<void> validateAndUpdatePodcastDuration(Podcast podcast) async {
    try {
      final audioFile = File(podcast.audioUrl);
      if (await audioFile.exists()) {
        final actualDuration = await _getAudioDuration(podcast.audioUrl);
        
        // Check if the stored duration is significantly different from actual duration
        final durationDifference = (podcast.duration.inSeconds - actualDuration.inSeconds).abs();
        
        if (durationDifference > 5) { // If difference is more than 5 seconds
          print('Duration mismatch detected for podcast: ${podcast.title}');
          print('Stored duration: ${podcast.duration.inSeconds} seconds');
          print('Actual duration: ${actualDuration.inSeconds} seconds');
          print('Difference: $durationDifference seconds');
          
          // Update the podcast with correct duration
          final updatedPodcast = podcast.copyWith(duration: actualDuration);
          await _savePodcast(updatedPodcast);
          
          print('Podcast duration updated successfully');
        } else {
          print('Duration is accurate for podcast: ${podcast.title}');
        }
      } else {
        print('Audio file not found for podcast: ${podcast.title}');
      }
    } catch (e) {
      print('Error validating podcast duration: $e');
    }
  }
} 