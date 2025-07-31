import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService = GeminiService();
  final SpeechService _speechService = SpeechService();
  final TTSService _ttsService = TTSService();

  Conversation? _currentConversation;
  final List<ConversationMessage> _messages = [];
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _partialText = '';
  String? _error;
  bool _isFirebaseAvailable = false;

  // Getters
  Conversation? get currentConversation => _currentConversation;
  List<ConversationMessage> get messages => _messages;
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  String get partialText => _partialText;
  String? get error => _error;

  // Initialize the provider
  Future<void> initialize() async {
    try {
      // Initialize Firebase auth (optional)
      try {
        final userCredential = await _firebaseService.signInAnonymously();
        if (userCredential?.user != null) {
          // Create new conversation
          _currentConversation = _firebaseService.createNewConversation(
            userCredential!.user!.uid,
          );
          await _firebaseService.saveConversation(_currentConversation!);
          _isFirebaseAvailable = true;
        }
      } catch (e) {
        print('Firebase initialization failed: $e');
        _isFirebaseAvailable = false;
        // Create local conversation without Firebase
        _currentConversation = Conversation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'local_user',
          messages: [],
          createdAt: DateTime.now(),
        );
      }

      // Initialize speech services
      await _speechService.initialize();
      await _ttsService.initialize();

      notifyListeners();
    } catch (e) {
      _error = 'Initialization failed: $e';
      notifyListeners();
    }
  }

  // Start listening for speech
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

  // Process user message and generate AI response
  Future<void> _processUserMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Add user message to conversation
      final userMessage = ConversationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      _messages.add(userMessage);
      notifyListeners();

      // Check for crisis message
      if (_geminiService.isCrisisMessage(message)) {
        final crisisResponse = "Anlattıkların çok ciddi ve önemli. Bu konuda profesyonel destek alabilecek biriyle konuşman hayati önem taşıyor. Lütfen derhal 112 Acil Çağrı Merkezi'ni ara. Sana yardım etmek için oradalar.";
        
        final aiMessage = ConversationMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: crisisResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );

        _messages.add(aiMessage);
        await _speakResponse(crisisResponse);
      } else {
        // Generate AI response
        final aiResponse = await _geminiService.generateResponse(message, _messages);
        
        final aiMessage = ConversationMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );

        _messages.add(aiMessage);
        await _speakResponse(aiResponse);
      }

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

    } catch (e) {
      _error = 'Failed to process message: $e';
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Speak AI response
  Future<void> _speakResponse(String text) async {
    try {
      _isSpeaking = true;
      notifyListeners();

      await _ttsService.speak(text);
      
      // Wait a bit for speech to complete
      await Future.delayed(const Duration(seconds: 2));
      
    } catch (e) {
      _error = 'Text-to-speech failed: $e';
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
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