import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firestore methods for conversations
  Future<void> saveConversation(Conversation conversation) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversation.id)
          .set(conversation.toMap());
    } catch (e) {
      print('Error saving conversation: $e');
      rethrow;
    }
  }

  Future<void> updateConversation(Conversation conversation) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversation.id)
          .update(conversation.toMap());
    } catch (e) {
      print('Error updating conversation: $e');
      rethrow;
    }
  }

  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (doc.exists) {
        return Conversation.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  Stream<List<Conversation>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromMap(doc.data()))
            .toList());
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .delete();
    } catch (e) {
      print('Error deleting conversation: $e');
      rethrow;
    }
  }

  // Helper method to create a new conversation
  Conversation createNewConversation(String userId) {
    return Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      messages: [],
      createdAt: DateTime.now(),
    );
  }

  // Helper method to add message to conversation
  Conversation addMessageToConversation(
    Conversation conversation,
    ConversationMessage message,
  ) {
    final updatedMessages = List<ConversationMessage>.from(conversation.messages)
      ..add(message);
    
    return Conversation(
      id: conversation.id,
      userId: conversation.userId,
      messages: updatedMessages,
      createdAt: conversation.createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 