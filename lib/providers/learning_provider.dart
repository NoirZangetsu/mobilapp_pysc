import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../models/flashcard.dart';
import '../models/podcast.dart';
import '../services/document_service.dart';
import '../services/flashcard_service.dart';
import '../services/podcast_service.dart';
import 'package:flutter/material.dart'; // Added for context.read
import '../providers/auth_provider.dart'; // Added for AuthProvider

class LearningProvider extends ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  final FlashcardService _flashcardService = FlashcardService();
  final PodcastService _podcastService = PodcastService();

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

  // Initialize provider
  Future<void> initialize(String userId) async {
    try {
      // No need to load documents since we don't save them
      _documents = [];

      // Load user flashcard decks
      _flashcardService.getUserFlashcardDecks(userId).listen((decks) {
        _flashcardDecks = decks;
        notifyListeners();
      });

      // Load user podcasts
      _podcastService.getUserPodcasts(userId).listen((podcasts) {
        _podcasts = podcasts;
        notifyListeners();
      });
    } catch (e) {
      print('Learning provider initialization failed: $e');
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
        'AI Oluşturulan Kartlar',
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

  // Process podcast request from AI assistant
  Future<void> processPodcastRequest(String request, String userId) async {
    try {
      _isCreatingPodcast = true;
      _podcastError = null;
      notifyListeners();

      // Parse the request and create podcast
      // This is a simplified implementation - in a real app, you'd use AI to parse the request
      await createPodcastFromTopic(
        userId,
        request,
        'AI Oluşturulan Podcast',
        voiceStyle: 'professional',
        language: 'tr-TR',
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
    {String voiceStyle = 'professional', String language = 'tr-TR'}
  ) async {
    try {
      _isCreatingPodcast = true;
      _podcastError = null;
      notifyListeners();

      await _podcastService.createPodcastFromTopic(
        userId,
        topic,
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