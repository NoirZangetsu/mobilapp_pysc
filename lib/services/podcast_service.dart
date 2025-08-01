import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../models/podcast.dart';
import '../models/document.dart';
import 'gemini_service.dart';

class PodcastService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GeminiService _geminiService = GeminiService();

  // Create podcast from topic
  Future<Podcast> createPodcastFromTopic(
    String userId,
    String topic,
    String title,
    {String voiceStyle = 'professional', String language = 'tr-TR'}
  ) async {
    try {
      final prompt = '''
Aşağıdaki konu hakkında bir podcast senaryosu oluştur.

Konu: $topic

Senaryo şu bölümleri içermeli:
1. Giriş (30 saniye)
2. Ana içerik (3-5 dakika)
3. Özet ve kapanış (30 saniye)

Ses tonu: $voiceStyle
Dil: $language

Lütfen aşağıdaki JSON formatında yanıt ver:
{
  "title": "Podcast başlığı",
  "description": "Podcast açıklaması",
  "script": "Sesli okunacak metin",
  "estimatedDuration": 300
}
''';

      final response = await _geminiService.generateResponse(prompt, []);
      final podcastData = _parsePodcastFromResponse(response);
      
      // Generate audio from script
      final audioUrl = await _generateAudioFromText(
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
        sourceType: 'topic',
        sourceId: topic,
        audioUrl: audioUrl,
        duration: Duration(seconds: podcastData['estimatedDuration'] ?? 300),
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
1. Giriş (30 saniye)
2. Ana içerik (3-5 dakika)
3. Özet ve kapanış (30 saniye)

Ses tonu: $voiceStyle
Dil: $language

Lütfen aşağıdaki JSON formatında yanıt ver:
{
  "title": "Podcast başlığı",
  "description": "Podcast açıklaması",
  "script": "Sesli okunacak metin",
  "estimatedDuration": 300
}
''';

      final response = await _geminiService.generateResponse(prompt, []);
      final podcastData = _parsePodcastFromResponse(response);
      
      // Generate audio from script
      final audioUrl = await _generateAudioFromText(
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
        duration: Duration(seconds: podcastData['estimatedDuration'] ?? 300),
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
      // Extract JSON object from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('JSON formatı bulunamadı');
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Podcast ayrıştırma hatası: $e');
    }
  }

  // Generate audio from text (placeholder implementation)
  Future<String> _generateAudioFromText(
    String script,
    String voiceStyle,
    String language,
  ) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'podcast_$timestamp.mp3';
      
      // Create storage reference
      final storageRef = _storage
          .ref()
          .child('podcasts')
          .child(filename);
      
      // For now, create a dummy audio file
      // In production, this should use a proper TTS service
      final dummyAudioBytes = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF header
        0x24, 0x00, 0x00, 0x00, // File size
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
      ]);
      
      // Upload to Firebase Storage
      await storageRef.putData(dummyAudioBytes);
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Audio generation error: $e');
      // Return a placeholder URL if generation fails
      return 'https://example.com/placeholder-audio.mp3';
    }
  }

  // Save podcast to Firestore
  Future<void> _savePodcast(Podcast podcast) async {
    await _firestore
        .collection('users')
        .doc(podcast.userId)
        .collection('podcasts')
        .doc(podcast.id)
        .set(podcast.toMap());
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
        // Delete audio file from Storage
        try {
          final audioRef = _storage.refFromURL(podcast.audioUrl);
          await audioRef.delete();
        } catch (e) {
          print('Audio file deletion failed: $e');
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
} 