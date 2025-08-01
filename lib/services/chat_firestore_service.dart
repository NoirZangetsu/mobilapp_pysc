import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/chat_message.dart';

class ChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new chat session
  Future<String> createChatSession() async {
    try {
      if (currentUserId == null) {
        throw 'Kullanıcı giriş yapmamış';
      }

      DocumentReference chatRef = await _firestore.collection('chats').add({
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'messages': [],
        'title': 'Yeni Konuşma',
        'isActive': true,
      });

      return chatRef.id;
    } catch (e) {
      throw 'Chat oturumu oluşturulamadı: $e';
    }
  }

  // Add message to chat
  Future<void> addMessageToChat(String chatId, ChatMessage message) async {
    try {
      if (currentUserId == null) {
        throw 'Kullanıcı giriş yapmamış';
      }

      await _firestore.collection('chats').doc(chatId).update({
        'messages': FieldValue.arrayUnion([message.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'title': message.isUser ? message.content.substring(0, math.min(50, message.content.length)) : null,
      });
    } catch (e) {
      throw 'Mesaj eklenemedi: $e';
    }
  }

  // Get chat messages
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      
      List<dynamic> messagesData = doc.data()?['messages'] ?? [];
      return messagesData
          .map((msg) => ChatMessage.fromMap(msg as Map<String, dynamic>))
          .toList();
    });
  }

  // Get user's chat sessions
  Stream<List<ChatSession>> getUserChatSessions() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        return ChatSession(
          id: doc.id,
          title: data['title'] ?? 'Yeni Konuşma',
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
          messageCount: (data['messages'] as List?)?.length ?? 0,
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    });
  }

  // Update chat session
  Future<void> updateChatSession(String chatId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        ...updates,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Chat oturumu güncellenemedi: $e';
    }
  }

  // Delete chat session
  Future<void> deleteChatSession(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      throw 'Chat oturumu silinemedi: $e';
    }
  }

  // Archive chat session
  Future<void> archiveChatSession(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isActive': false,
        'archivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Chat oturumu arşivlenemedi: $e';
    }
  }

  // Get chat session details
  Future<ChatSession?> getChatSession(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!doc.exists) return null;
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return ChatSession(
        id: doc.id,
        title: data['title'] ?? 'Yeni Konuşma',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
        messageCount: (data['messages'] as List?)?.length ?? 0,
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      throw 'Chat oturumu alınamadı: $e';
    }
  }

  // Search chat messages
  Future<List<ChatMessage>> searchChatMessages(String chatId, String query) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!doc.exists) return [];
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> messagesData = data['messages'] ?? [];
      List<ChatMessage> messages = messagesData
          .map((msg) => ChatMessage.fromMap(msg as Map<String, dynamic>))
          .toList();
      
      // Simple text search
      return messages.where((message) {
        return message.content.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      throw 'Mesaj arama hatası: $e';
    }
  }

  // Export chat data
  Future<Map<String, dynamic>> exportChatData(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!doc.exists) {
        throw 'Chat oturumu bulunamadı';
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'chatId': chatId,
        'title': data['title'] ?? 'Yeni Konuşma',
        'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
        'lastUpdated': (data['lastUpdated'] as Timestamp).toDate().toIso8601String(),
        'messages': data['messages'] ?? [],
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw 'Chat verisi dışa aktarılamadı: $e';
    }
  }

  // Get chat statistics
  Future<ChatStatistics> getChatStatistics() async {
    try {
      if (currentUserId == null) {
        throw 'Kullanıcı giriş yapmamış';
      }

      QuerySnapshot snapshot = await _firestore
          .collection('chats')
          .where('userId', isEqualTo: currentUserId)
          .get();

      int totalChats = snapshot.docs.length;
      int totalMessages = 0;
      DateTime? firstChatDate;
      DateTime? lastChatDate;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> messages = data['messages'] ?? [];
        totalMessages += messages.length;

        DateTime chatDate = (data['createdAt'] as Timestamp).toDate();
        if (firstChatDate == null || chatDate.isBefore(firstChatDate)) {
          firstChatDate = chatDate;
        }
        if (lastChatDate == null || chatDate.isAfter(lastChatDate)) {
          lastChatDate = chatDate;
        }
      }

      return ChatStatistics(
        totalChats: totalChats,
        totalMessages: totalMessages,
        firstChatDate: firstChatDate,
        lastChatDate: lastChatDate,
        averageMessagesPerChat: totalChats > 0 ? totalMessages / totalChats : 0,
      );
    } catch (e) {
      throw 'Chat istatistikleri alınamadı: $e';
    }
  }
}

// Chat Session Model
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int messageCount;
  final bool isActive;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdated,
    required this.messageCount,
    required this.isActive,
  });
}

// Chat Statistics Model
class ChatStatistics {
  final int totalChats;
  final int totalMessages;
  final DateTime? firstChatDate;
  final DateTime? lastChatDate;
  final double averageMessagesPerChat;

  ChatStatistics({
    required this.totalChats,
    required this.totalMessages,
    this.firstChatDate,
    this.lastChatDate,
    required this.averageMessagesPerChat,
  });
} 