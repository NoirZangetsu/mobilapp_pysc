import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/document.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/document_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();
  final SpeechService _speechService = SpeechService();
  final TTSService _ttsService = TTSService();
  final DocumentService _documentService = DocumentService();

  Conversation? _currentConversation;
  final List<ConversationMessage> _messages = [];
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _partialText = '';
  String? _error;
  bool _isFirebaseAvailable = false;
  Document? _currentDocument;
  List<Document> _userDocuments = [];

  // Context management
  static const int _maxContextMessages = 15;
  static const int _maxMessageLength = 2000;

  // Getters
  Conversation? get currentConversation => _currentConversation;
  List<ConversationMessage> get messages => _messages;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  String get partialText => _partialText;
  String? get error => _error;
  Document? get currentDocument => _currentDocument;
  List<Document> get userDocuments => _userDocuments;
  
  Future<void> initialize() async {
    try {
      await _initializeFirebase();
      await _initializeSpeechServices();
      notifyListeners();
    } catch (e) {
      _error = 'Initialization failed: $e';
      notifyListeners();
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      final userCredential = await _firebaseService.signInAnonymously();
      if (userCredential?.user != null) {
        await _loadOrCreateConversation(userCredential!.user!.uid);
        _isFirebaseAvailable = true;
        await _loadUserDocuments(userCredential.user!.uid);
      }
    } catch (e) {
      _createLocalConversation();
    }
  }

  Future<void> _loadOrCreateConversation(String userId) async {
    _currentConversation = await _firebaseService.getLatestConversation(userId);
    
    if (_currentConversation == null) {
      _currentConversation = _firebaseService.createNewConversation(userId);
      await _firebaseService.saveConversation(_currentConversation!);
    } else {
      _messages.clear();
      _messages.addAll(_currentConversation!.messages);
    }
  }

  void _createLocalConversation() {
    _isFirebaseAvailable = false;
    _currentConversation = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'local_user',
      messages: [],
      createdAt: DateTime.now(),
    );
  }

  Future<void> _initializeSpeechServices() async {
    await _speechService.initialize();
    await _ttsService.initialize();
  }

  Future<void> _loadUserDocuments(String userId) async {
    try {
      _userDocuments = [];
      notifyListeners();
    } catch (e) {
      print('Failed to load user documents: $e');
    }
  }

  // Process PDF file and set as current document with enhanced processing
  Future<void> processPDFFile(String filePath, String userId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final document = await _documentService.processPDFFile(filePath, userId);
      if (document != null) {
        setCurrentDocument(document);
        
        // Add enhanced system message about document
        final systemMessage = ConversationMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '📄 PDF dosyası başarıyla yüklendi: **${document.fileName}**\n\n✅ Artık bu belge ile ilgili sorular sorabilirsin. AI, belge içeriğini analiz ederek detaylı yanıtlar verecek.',
          isUser: false,
          timestamp: DateTime.now(),
          isSystemMessage: true,
        );
        _addMessageToContext(systemMessage);
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'PDF işleme hatası: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Process image file and set as current document with enhanced processing
  Future<void> processImageFile(String filePath, String userId) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final document = await _documentService.processImageFile(filePath, userId);
      if (document != null) {
        setCurrentDocument(document);
        
        // Add enhanced system message about image
        final systemMessage = ConversationMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '🖼️ Görüntü dosyası başarıyla yüklendi: **${document.fileName}**\n\n✅ Artık bu görüntü ile ilgili sorular sorabilirsin. AI, görsel içeriği analiz ederek detaylı açıklamalar yapacak.',
          isUser: false,
          timestamp: DateTime.now(),
          isSystemMessage: true,
        );
        _addMessageToContext(systemMessage);
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Görüntü işleme hatası: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Send text message with enhanced processing
  Future<void> sendTextMessage(String message) async {
    await _processUserMessage(message);
  }

  // Set current document for context with enhanced management
  void setCurrentDocument(Document? document) {
    _currentDocument = document;
    
    if (document != null) {
      // Add context message about document change
      final contextMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📋 Aktif doküman değiştirildi: **${document.fileName}**',
        isUser: false,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );
      _addMessageToContext(contextMessage);
    }
    
    notifyListeners();
  }

  // Ask question about document with enhanced processing
  Future<void> askDocumentQuestion(String question, String userId) async {
    if (question.trim().isEmpty) return;

    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Add user question to conversation with enhanced formatting
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '❓ **Soru:** $question',
        isUser: true,
        timestamp: DateTime.now(),
        documentId: _currentDocument?.id,
      );

      _addMessageToContext(userMessage);

      // Generate AI response with document context
      String aiResponse;
      if (_currentDocument != null) {
        // Use document content directly with enhanced context
        final documentContent = _currentDocument!.content ?? '';
        final enhancedQuestion = _enhanceQuestionWithContext(question, documentContent);

        aiResponse = await _geminiService.generateResponseWithDocument(
          enhancedQuestion,
          _getOptimizedContext(),
          documentContent,
        );
      } else {
        // Regular chat without document context
        aiResponse = await _geminiService.generateResponse(question, _getOptimizedContext());
      }

      final aiMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🤖 **AI Yanıtı:**\n$aiResponse',
        isUser: false,
        timestamp: DateTime.now(),
        documentId: _currentDocument?.id,
      );

      _addMessageToContext(aiMessage);
      await _speakResponse(aiResponse);

      // Update conversation in Firebase (if available)
      if (_isFirebaseAvailable && _currentConversation != null) {
        try {
          _currentConversation = _firebaseService.addMessageToConversation(
            _currentConversation!,
            userMessage,
          );
          await _firebaseService.updateConversation(_currentConversation!);
        } catch (e) {
          print('Failed to update Firebase: $e');
        }
      }

      notifyListeners();

    } catch (e) {
      _error = 'Failed to process document question: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Start listening for speech with enhanced feedback
  Future<void> startListening() async {
    if (_isListening || _isProcessing) return;

    try {
      _isListening = true;
      _partialText = '';
      _error = null;
      notifyListeners();

      await _speechService.startListening(
        onResult: (text) {
          _partialText = text;
          notifyListeners();
        },
        onListeningComplete: () async {
          _isListening = false;
          if (_partialText.isNotEmpty) {
            await _processUserMessage(_partialText);
          }
          _partialText = '';
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Speech recognition failed: $e';
      _isListening = false;
      notifyListeners();
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechService.stopListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error stopping speech recognition: $e';
      notifyListeners();
    }
  }

  // Process user message and generate AI response with enhanced processing
  Future<void> _processUserMessage(String message) async {
    if (message.trim().isEmpty) return;

    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Add user message to conversation with enhanced formatting
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '👤 **Kullanıcı:** $message',
        isUser: true,
        timestamp: DateTime.now(),
      );

      _addMessageToContext(userMessage);

      // Generate AI response with multimodal capabilities
      String aiResponse;
      
      if (_currentDocument != null && _currentDocument!.content != null) {
        // Use multimodal response with document content
        final enhancedQuestion = _enhanceQuestionWithContext(message, _currentDocument!.content!);
        aiResponse = await _geminiService.generateResponseWithDocument(
          enhancedQuestion,
          _getOptimizedContext(),
          _currentDocument!.content!,
        );
      } else {
        // Regular text response with enhanced context
        aiResponse = await _geminiService.generateResponse(message, _getOptimizedContext());
      }
      
      final aiMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🤖 **AI Asistanı:**\n$aiResponse',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _addMessageToContext(aiMessage);
      await _speakResponse(aiResponse);

      // Update conversation in Firebase (if available)
      if (_isFirebaseAvailable && _currentConversation != null) {
        try {
          _currentConversation = _firebaseService.addMessageToConversation(
            _currentConversation!,
            userMessage,
          );
          await _firebaseService.updateConversation(_currentConversation!);
        } catch (e) {
          print('Failed to update Firebase: $e');
        }
      }

      notifyListeners();

    } catch (e) {
      _error = 'Failed to process message: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Process image and generate response with enhanced processing
  Future<void> processImageWithQuestion(String question, File imageFile) async {
    if (question.trim().isEmpty) return;

    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Add user message to conversation
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🖼️ **Görsel Analizi:** $question',
        isUser: true,
        timestamp: DateTime.now(),
      );

      _addMessageToContext(userMessage);

      // Generate multimodal response with image
      final aiResponse = await _geminiService.generateResponseWithImage(
        question,
        _getOptimizedContext(),
        imageFile,
      );
      
      final aiMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🤖 **AI Görsel Analizi:**\n$aiResponse',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _addMessageToContext(aiMessage);
      await _speakResponse(aiResponse);

      // Update conversation in Firebase (if available)
      if (_isFirebaseAvailable && _currentConversation != null) {
        try {
          _currentConversation = _firebaseService.addMessageToConversation(
            _currentConversation!,
            userMessage,
          );
          await _firebaseService.updateConversation(_currentConversation!);
        } catch (e) {
          print('Failed to update Firebase: $e');
        }
      }

      notifyListeners();

    } catch (e) {
      _error = 'Failed to process image: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Process image and document together with enhanced processing
  Future<void> processImageAndDocumentWithQuestion(
    String question, 
    File imageFile, 
    String documentContent,
  ) async {
    if (question.trim().isEmpty) return;

    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Add user message to conversation
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📄🖼️ **Belge + Görsel Analizi:** $question',
        isUser: true,
        timestamp: DateTime.now(),
      );

      _addMessageToContext(userMessage);

      // Generate multimodal response with image and document
      final aiResponse = await _geminiService.generateResponseWithImageAndDocument(
        question,
        _getOptimizedContext(),
        imageFile,
        documentContent,
      );
      
      final aiMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🤖 **AI Kapsamlı Analiz:**\n$aiResponse',
        isUser: false,
        timestamp: DateTime.now(),
      );

      _addMessageToContext(aiMessage);
      await _speakResponse(aiResponse);

      // Update conversation in Firebase (if available)
      if (_isFirebaseAvailable && _currentConversation != null) {
        try {
          _currentConversation = _firebaseService.addMessageToConversation(
            _currentConversation!,
            userMessage,
          );
          await _firebaseService.updateConversation(_currentConversation!);
        } catch (e) {
          print('Failed to update Firebase: $e');
        }
      }

      notifyListeners();

    } catch (e) {
      _error = 'Failed to process image and document: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Generate educational flashcards from content
  Future<String> generateFlashcards(String content, String topic) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final flashcards = await _geminiService.generateEducationalContent(
        content,
        topic,
        'flashcard',
      );

      // Add system message about flashcard generation
      final systemMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🎴 **Flashcard Oluşturuldu:** $topic konusu için eğitimsel kartlar hazırlandı.',
        isUser: false,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );
      _addMessageToContext(systemMessage);

      notifyListeners();

      return flashcards;

    } catch (e) {
      _error = 'Flashcard oluşturma hatası: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Generate educational podcast from content
  Future<String> generatePodcast(String content, String topic) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final podcast = await _geminiService.generateEducationalContent(
        content,
        topic,
        'podcast',
      );

      // Add system message about podcast generation
      final systemMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '🎙️ **Podcast Oluşturuldu:** $topic konusu için eğitimsel sesli içerik hazırlandı.',
        isUser: false,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );
      _addMessageToContext(systemMessage);

      notifyListeners();

      return podcast;

    } catch (e) {
      _error = 'Podcast oluşturma hatası: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Generate educational summary from content
  Future<String> generateSummary(String content, String topic) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      final summary = await _geminiService.generateEducationalContent(
        content,
        topic,
        'summary',
      );

      // Add system message about summary generation
      final systemMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '📋 **Özet Oluşturuldu:** $topic konusu için eğitimsel özet hazırlandı.',
        isUser: false,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );
      _addMessageToContext(systemMessage);

      notifyListeners();

      return summary;

    } catch (e) {
      _error = 'Özet oluşturma hatası: $e';
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Generate educational content from current document
  Future<String> generateEducationalContentFromDocument(String contentType) async {
    if (_currentDocument?.content == null) {
      throw Exception('Aktif doküman bulunamadı veya içerik boş.');
    }

    final content = _currentDocument!.content!;
    final topic = _currentDocument!.fileName ?? 'Doküman';

    switch (contentType) {
      case 'flashcard':
        return await generateFlashcards(content, topic);
      case 'podcast':
        return await generatePodcast(content, topic);
      case 'summary':
        return await generateSummary(content, topic);
      default:
        throw Exception('Geçersiz içerik türü: $contentType');
    }
  }

  // Speak AI response with enhanced TTS
  Future<void> _speakResponse(String text) async {
    try {
      _isSpeaking = true;
      notifyListeners();

      // Clean text for better TTS
      final cleanText = _cleanTextForTTS(text);
      await _ttsService.speak(cleanText);
      
      // Wait a bit for speech to complete
      await Future.delayed(const Duration(seconds: 2));
      
    } catch (e) {
      _error = 'Text-to-speech failed: $e';
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // Enhanced context management
  void _addMessageToContext(ConversationMessage message) {
    _messages.add(message);
    
    // Optimize context length
    if (_messages.length > _maxContextMessages) {
      // Keep system messages and recent messages
      final systemMessages = _messages.where((msg) => msg.isSystemMessage).toList();
      final recentMessages = _messages.take(_maxContextMessages ~/ 2).toList();
      _messages.clear();
      _messages.addAll([...systemMessages, ...recentMessages]);
    }
    
    notifyListeners();
  }

  // Get optimized context for AI
  List<ConversationMessage> _getOptimizedContext() {
    if (_messages.length <= _maxContextMessages) return _messages;
    
    // Keep system messages and most recent messages
    final systemMessages = _messages.where((msg) => msg.isSystemMessage).toList();
    final recentMessages = _messages.take(_maxContextMessages - systemMessages.length).toList();
    
    return [...systemMessages, ...recentMessages];
  }

  // Enhance question with context
  String _enhanceQuestionWithContext(String question, String documentContent) {
    return '''
📋 **Belge Bağlamı:** ${documentContent.substring(0, documentContent.length > 500 ? 500 : documentContent.length)}...

❓ **Soru:** $question

💡 Lütfen belge içeriğini dikkate alarak detaylı bir yanıt ver.
''';
  }

  // Clean text for TTS
  String _cleanTextForTTS(String text) {
    // Remove markdown and formatting
    return text
        .replaceAll(RegExp(r'\*\*.*?\*\*'), '') // Remove bold
        .replaceAll(RegExp(r'\*.*?\*'), '') // Remove italic
        .replaceAll(RegExp(r'#+ '), '') // Remove headers
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove links
        .replaceAll(RegExp(r'`.*?`'), '') // Remove code
        .trim();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear messages and start new conversation with enhanced cleanup
  void clearMessages() {
    _messages.clear();
    _currentDocument = null;
    _error = null;
    _partialText = '';
    
    // Add welcome message
    final welcomeMessage = ConversationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: '🎉 **Yeni Sohbet Başlatıldı**\n\nMerhaba! Ben senin öğrenme asistanın. Herhangi bir konuda soru sorabilir, PDF yükleyebilir veya görsel analizi yapabilirim.',
      isUser: false,
      timestamp: DateTime.now(),
      isSystemMessage: true,
    );
    _addMessageToContext(welcomeMessage);
    
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _speechService.stopListening();
    _ttsService.stop();
    super.dispose();
  }
} 