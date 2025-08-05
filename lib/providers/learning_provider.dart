import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../models/flashcard.dart';
import '../models/podcast.dart';
import '../services/document_service.dart';
import '../services/flashcard_service.dart';
import '../services/podcast_service.dart';
import 'package:flutter/material.dart'; // Added for context.read
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore

class LearningProvider extends ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  final FlashcardService _flashcardService = FlashcardService();
  final PodcastService _podcastService = PodcastService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Added for Firestore

  // Documents
  List<Document> _documents = [];
  bool _isUploadingDocument = false;
  String? _documentError;

  // Flashcards
  List<FlashcardDeck> _flashcardDecks = [];
  bool _isCreatingFlashcards = false;
  String? _flashcardError;

  // Podcasts
  List<Podcast> _podcasts = [];
  bool _isCreatingPodcast = false;
  String? _podcastError;

  // Getters
  List<Document> get documents => _documents;
  bool get isUploadingDocument => _isUploadingDocument;
  String? get documentError => _documentError;

  List<FlashcardDeck> get flashcardDecks => _flashcardDecks;
  bool get isCreatingFlashcards => _isCreatingFlashcards;
  String? get flashcardError => _flashcardError;

  List<Podcast> get podcasts => _podcasts;
  bool get isCreatingPodcast => _isCreatingPodcast;
  String? get podcastError => _podcastError;

  // Initialize provider with proper data loading
  Future<void> initialize(String userId) async {
    try {
      print('LearningProvider: Initializing for user $userId');
      
      // Clear existing data
      _documents = [];
      _flashcardDecks = [];
      _podcasts = [];
      
      // Load user flashcard decks with proper error handling
      try {
        final flashcardStream = _flashcardService.getUserFlashcardDecks(userId);
        flashcardStream.listen(
          (decks) {
            print('LearningProvider: Loaded ${decks.length} flashcard decks');
            _flashcardDecks = decks;
            notifyListeners();
          },
          onError: (error) {
            print('LearningProvider: Flashcard loading error: $error');
            _flashcardError = 'Flashcard yükleme hatası: $error';
            // Don't clear existing data on error
            notifyListeners();
          },
        );
      } catch (e) {
        print('LearningProvider: Flashcard service error: $e');
        _flashcardError = 'Flashcard servis hatası: $e';
        // Keep existing data if available
        notifyListeners();
      }

      // Load user podcasts with proper error handling
      try {
        final podcastStream = _podcastService.getUserPodcasts(userId);
        podcastStream.listen(
          (podcasts) async {
            print('LearningProvider: Loaded ${podcasts.length} podcasts');
            
            // Validate durations for all podcasts
            for (final podcast in podcasts) {
              await _podcastService.validateAndUpdatePodcastDuration(podcast);
            }
            
            _podcasts = podcasts;
            notifyListeners();
          },
          onError: (error) {
            print('LearningProvider: Podcast loading error: $error');
            _podcastError = 'Podcast yükleme hatası: $error';
            // Don't clear existing data on error
            notifyListeners();
          },
        );
      } catch (e) {
        print('LearningProvider: Podcast service error: $e');
        _podcastError = 'Podcast servis hatası: $e';
        // Keep existing data if available
        notifyListeners();
      }

      notifyListeners();
    } catch (e) {
      print('LearningProvider: Initialization failed: $e');
      _flashcardError = 'Başlatma hatası: $e';
      _podcastError = 'Başlatma hatası: $e';
      notifyListeners();
    }
  }

  // Load user data with enhanced error handling
  Future<void> loadUserData(String userId) async {
    try {
      print('LearningProvider: Loading user data for $userId');
      
      // Load data from Firestore
      await _loadPodcastsFromFirestore(userId);
      await _loadDocumentsFromFirestore(userId);
      await _loadFlashcardDecksFromFirestore(userId);
    } catch (e) {
      print('Error loading data: $e');
      rethrow;
    }
  }

  // Load podcasts from Firestore
  Future<void> _loadPodcastsFromFirestore(String userId) async {
    try {
      final podcastsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('podcasts')
          .orderBy('createdAt', descending: true)
          .get();
      
      _podcasts = podcastsSnapshot.docs
          .map((doc) => Podcast.fromMap(doc.data()))
          .toList();
      
      print('LearningProvider: Loaded ${_podcasts.length} podcasts from Firestore');
      notifyListeners();
    } catch (e) {
      print('Error loading podcasts: $e');
      rethrow;
    }
  }

  // Load documents from Firestore
  Future<void> _loadDocumentsFromFirestore(String userId) async {
    try {
      final documentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .orderBy('createdAt', descending: true)
          .get();
      
      _documents = documentsSnapshot.docs
          .map((doc) => Document.fromMap(doc.data()))
          .toList();
      
      print('LearningProvider: Loaded ${_documents.length} documents from Firestore');
      notifyListeners();
    } catch (e) {
      print('Error loading documents: $e');
      rethrow;
    }
  }

  // Load flashcard decks from Firestore
  Future<void> _loadFlashcardDecksFromFirestore(String userId) async {
    try {
      final flashcardSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcardDecks')
          .orderBy('createdAt', descending: true)
          .get();
      
      _flashcardDecks = flashcardSnapshot.docs
          .map((doc) => FlashcardDeck.fromMap(doc.data()))
          .toList();
      
      print('LearningProvider: Loaded ${_flashcardDecks.length} flashcard decks from Firestore');
      notifyListeners();
    } catch (e) {
      print('Error loading flashcard decks: $e');
      rethrow;
    }
  }

  // Process PDF file (without saving)
  Future<Document?> processPDFFile(String filePath, String userId) async {
    try {
      _isUploadingDocument = true;
      _documentError = null;
      notifyListeners();

      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      // Extract text from PDF
      final content = await _documentService.extractTextFromPDFFile(file);
      
      // Create temporary document
      final document = _documentService.createTempDocument(
        fileName: fileName,
        content: content,
        userId: userId,
      );

      _isUploadingDocument = false;
      notifyListeners();
      
      return document;
    } catch (e) {
      _documentError = 'PDF işleme hatası: $e';
      _isUploadingDocument = false;
      notifyListeners();
      return null;
    }
  }

  // Process image file (without saving)
  Future<Document?> processImageFile(String filePath, String userId) async {
    try {
      _isUploadingDocument = true;
      _documentError = null;
      notifyListeners();

      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      // Extract text from image (OCR functionality would be implemented here)
      final content = await _documentService.extractTextFromImageFile(file);
      
      // Create temporary document
      final document = _documentService.createTempDocument(
        fileName: fileName,
        content: content,
        userId: userId,
      );

      _isUploadingDocument = false;
      notifyListeners();
      
      return document;
    } catch (e) {
      _documentError = 'Görüntü işleme hatası: $e';
      _isUploadingDocument = false;
      notifyListeners();
      return null;
    }
  }

  // Process flashcard request from AI assistant
  Future<void> processFlashcardRequest(String request, String userId, {int cardCount = 10}) async {
    try {
      _isCreatingFlashcards = true;
      _flashcardError = null;
      notifyListeners();

      // Parse the request and create flashcards
      // This is a simplified implementation - in a real app, you'd use AI to parse the request
      await createFlashcardsFromTopic(
        userId,
        request,
        'Bilgi Kartları', // Simplified title
        cardCount: cardCount,
      );

      _isCreatingFlashcards = false;
      notifyListeners();
    } catch (e) {
      _flashcardError = 'Flashcard isteği işleme hatası: $e';
      _isCreatingFlashcards = false;
      notifyListeners();
    }
  }

  // Process podcast request
  Future<void> processPodcastRequest(
    String text,
    String userId, {
    String voiceStyle = 'professional',
    String contentLength = 'detailed',
    String language = 'tr-TR',
  }) async {
    try {
      _isCreatingPodcast = true;
      _podcastError = null;
      notifyListeners();

      // Parse the request and create podcast with enhanced options
      await createPodcastFromTopic(
        userId,
        text,
        'Podcast', // Simplified title
        voiceStyle: voiceStyle,
        language: language,
        contentLength: contentLength,
      );

      _isCreatingPodcast = false;
      notifyListeners();
    } catch (e) {
      _podcastError = 'Podcast isteği işleme hatası: $e';
      _isCreatingPodcast = false;
      notifyListeners();
    }
  }

  // Flashcard methods
  Future<void> createFlashcardsFromTopic(
    String userId,
    String topic,
    String title,
    {int cardCount = 10}
  ) async {
    try {
      _isCreatingFlashcards = true;
      _flashcardError = null;
      notifyListeners();

      await _flashcardService.createFlashcardsFromTopic(
        userId,
        topic,
        title,
        cardCount: cardCount,
      );

      _isCreatingFlashcards = false;
      notifyListeners();
    } catch (e) {
      _flashcardError = 'Flashcard oluşturma hatası: $e';
      _isCreatingFlashcards = false;
      notifyListeners();
    }
  }

  Future<void> createFlashcardsFromDocument(
    String userId,
    Document document,
    String title,
    {int cardCount = 10}
  ) async {
    try {
      _isCreatingFlashcards = true;
      _flashcardError = null;
      notifyListeners();

      await _flashcardService.createFlashcardsFromDocument(
        userId,
        document,
        title,
        cardCount: cardCount,
      );

      _isCreatingFlashcards = false;
      notifyListeners();
    } catch (e) {
      _flashcardError = 'Flashcard oluşturma hatası: $e';
      _isCreatingFlashcards = false;
      notifyListeners();
    }
  }

  void clearFlashcardError() {
    _flashcardError = null;
    notifyListeners();
  }

  // Podcast methods
  Future<void> createPodcastFromTopic(
    String userId,
    String topic,
    String title,
    {String voiceStyle = 'professional', String language = 'tr-TR', String contentLength = 'detailed'}
  ) async {
    try {
      _isCreatingPodcast = true;
      _podcastError = null;
      notifyListeners();

      print('Creating podcast: $title about $topic');
      
      final podcast = await _podcastService.createPodcastFromTopic(
        userId,
        topic,
        title,
        voiceStyle: voiceStyle,
        language: language,
        contentLength: contentLength,
      );

      print('Podcast created successfully: ${podcast.title}');
      print('Podcast ID: ${podcast.id}');
      print('Audio URL: ${podcast.audioUrl}');

      _isCreatingPodcast = false;
      notifyListeners();
    } catch (e) {
      print('Podcast creation error: $e');
      _podcastError = 'Podcast oluşturma hatası: $e';
      _isCreatingPodcast = false;
      notifyListeners();
    }
  }

  Future<void> createPodcastFromDocument(
    String userId,
    Document document,
    String title,
    {String voiceStyle = 'professional', String language = 'tr-TR'}
  ) async {
    try {
      _isCreatingPodcast = true;
      _podcastError = null;
      notifyListeners();

      await _podcastService.createPodcastFromDocument(
        userId,
        document,
        title,
        voiceStyle: voiceStyle,
        language: language,
      );

      _isCreatingPodcast = false;
      notifyListeners();
    } catch (e) {
      _podcastError = 'Podcast oluşturma hatası: $e';
      _isCreatingPodcast = false;
      notifyListeners();
    }
  }

  void clearPodcastError() {
    _podcastError = null;
    notifyListeners();
  }

  // Get specific items
  Future<FlashcardDeck?> getFlashcardDeck(String userId, String deckId) async {
    try {
      return await _flashcardService.getFlashcardDeck(userId, deckId);
    } catch (e) {
      throw Exception('Flashcard deck getirme hatası: $e');
    }
  }

  Future<Podcast?> getPodcast(String userId, String podcastId) async {
    try {
      return await _podcastService.getPodcast(userId, podcastId);
    } catch (e) {
      throw Exception('Podcast getirme hatası: $e');
    }
  }

  // Delete methods
  Future<void> deleteFlashcardDeck(String userId, String deckId) async {
    try {
      await _flashcardService.deleteFlashcardDeck(userId, deckId);
    } catch (e) {
      throw Exception('Flashcard deck silme hatası: $e');
    }
  }

  Future<void> deletePodcast(String userId, String podcastId) async {
    try {
      await _podcastService.deletePodcast(userId, podcastId);
    } catch (e) {
      throw Exception('Podcast silme hatası: $e');
    }
  }
} 