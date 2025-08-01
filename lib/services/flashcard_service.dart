import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard.dart';
import '../models/document.dart';
import 'gemini_service.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

  // Create flashcards from topic
  Future<FlashcardDeck> createFlashcardsFromTopic(
    String userId,
    String topic,
    String title,
    {int cardCount = 10}
  ) async {
    try {
      final prompt = '''
Aşağıdaki konu hakkında $cardCount adet flashcard oluştur. 
Her flashcard bir soru ve cevap içermeli.

Konu: $topic

Lütfen aşağıdaki JSON formatında yanıt ver:
[
  {
    "question": "Soru metni",
    "answer": "Cevap metni"
  }
]

Sorular çeşitli zorluk seviyelerinde olmalı ve konunun farklı yönlerini kapsamalı.
''';

      final response = await _geminiService.generateResponse(prompt, []);
      final cards = _parseFlashcardsFromResponse(response);
      
      final deckId = DateTime.now().millisecondsSinceEpoch.toString();
      final deck = FlashcardDeck(
        id: deckId,
        userId: userId,
        title: title,
        description: '$topic konusu hakkında oluşturulan bilgi kartları',
        sourceType: 'topic',
        sourceId: topic,
        createdAt: DateTime.now(),
        cardCount: cards.length,
        cards: cards,
      );

      await _saveFlashcardDeck(deck);
      return deck;
    } catch (e) {
      throw Exception('Flashcard oluşturma başarısız: $e');
    }
  }

  // Create flashcards from document
  Future<FlashcardDeck> createFlashcardsFromDocument(
    String userId,
    Document document,
    String title,
    {int cardCount = 10}
  ) async {
    try {
      // Get document content
      final documentContent = document.content ?? '';
      
      if (documentContent.isEmpty) {
        throw Exception('Document content is empty');
      }

      final prompt = '''
Aşağıdaki doküman içeriğinden $cardCount adet flashcard oluştur.

Doküman: ${document.fileName}
İçerik: $documentContent

Lütfen aşağıdaki JSON formatında yanıt ver:
[
  {
    "question": "Soru metni",
    "answer": "Cevap metni"
  }
]

Sorular dokümanın ana konularını kapsamalı ve çeşitli zorluk seviyelerinde olmalı.
''';

      final response = await _geminiService.generateResponse(prompt, []);
      final cards = _parseFlashcardsFromResponse(response);
      
      final deckId = DateTime.now().millisecondsSinceEpoch.toString();
      final deck = FlashcardDeck(
        id: deckId,
        userId: userId,
        title: title,
        description: '${document.fileName} dokümanından oluşturulan bilgi kartları',
        sourceType: 'document',
        sourceId: document.id,
        createdAt: DateTime.now(),
        cardCount: cards.length,
        cards: cards,
      );

      await _saveFlashcardDeck(deck);
      return deck;
    } catch (e) {
      throw Exception('Flashcard oluşturma başarısız: $e');
    }
  }

  // Parse flashcards from AI response
  List<Flashcard> _parseFlashcardsFromResponse(String response) {
    try {
      // Clean the response and extract JSON
      String cleanedResponse = response.trim();
      
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
      
      cleanedResponse = cleanedResponse.trim();
      
      // Try to find JSON array in the response
      final jsonStart = cleanedResponse.indexOf('[');
      final jsonEnd = cleanedResponse.lastIndexOf(']');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        final jsonString = cleanedResponse.substring(jsonStart, jsonEnd + 1);
        final List<dynamic> jsonList = jsonDecode(jsonString);
        
        final List<Flashcard> cards = [];
        for (int i = 0; i < jsonList.length; i++) {
          final cardData = jsonList[i] as Map<String, dynamic>;
          
          final card = Flashcard(
            id: 'card_$i',
            deckId: '',
            question: cardData['question']?.toString() ?? '',
            answer: cardData['answer']?.toString() ?? '',
            createdAt: DateTime.now(),
          );
          
          cards.add(card);
        }
        
        return cards;
      }
      
      // If no valid JSON found, create a simple flashcard from the response
      return [
        Flashcard(
          id: 'card_0',
          deckId: '',
          question: 'Oluşturulan İçerik',
          answer: response,
          createdAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      print('JSON parse error: $e');
      print('Response: $response');
      
      // Fallback: create a simple flashcard
      return [
        Flashcard(
          id: 'card_0',
          deckId: '',
          question: 'Hata Oluştu',
          answer: 'Flashcard oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.',
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  // Save flashcard deck to Firestore
  Future<void> _saveFlashcardDeck(FlashcardDeck deck) async {
    await _firestore
        .collection('users')
        .doc(deck.userId)
        .collection('flashcardDecks')
        .doc(deck.id)
        .set(deck.toMap());
  }

  // Get user's flashcard decks
  Stream<List<FlashcardDeck>> getUserFlashcardDecks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('flashcardDecks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FlashcardDeck.fromMap(doc.data()))
          .toList();
    });
  }

  // Get specific flashcard deck
  Future<FlashcardDeck?> getFlashcardDeck(String userId, String deckId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcardDecks')
          .doc(deckId)
          .get();
      
      if (doc.exists) {
        return FlashcardDeck.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Flashcard deck getirme hatası: $e');
    }
  }

  // Update flashcard review data
  Future<void> updateFlashcardReview(
    String userId,
    String deckId,
    String cardId,
    int difficulty,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcardDecks')
          .doc(deckId)
          .collection('cards')
          .doc(cardId)
          .update({
        'difficulty': difficulty,
        'reviewCount': FieldValue.increment(1),
        'lastReviewed': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Flashcard güncelleme hatası: $e');
    }
  }

  // Delete flashcard deck
  Future<void> deleteFlashcardDeck(String userId, String deckId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('flashcardDecks')
          .doc(deckId)
          .delete();
    } catch (e) {
      throw Exception('Flashcard deck silme hatası: $e');
    }
  }
} 