class ConversationMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? audioUrl;
  final bool isSystemMessage;
  final String? documentId;

  ConversationMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.audioUrl,
    this.isSystemMessage = false,
    this.documentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'audioUrl': audioUrl,
      'isSystemMessage': isSystemMessage,
      'documentId': documentId,
    };
  }

  factory ConversationMessage.fromMap(Map<String, dynamic> map) {
    return ConversationMessage(
      id: map['id'],
      content: map['content'],
      isUser: map['isUser'],
      timestamp: DateTime.parse(map['timestamp']),
      audioUrl: map['audioUrl'],
      isSystemMessage: map['isSystemMessage'] ?? false,
      documentId: map['documentId'],
    );
  }
}

class Conversation {
  final String id;
  final String userId;
  final List<ConversationMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      userId: map['userId'],
      messages: (map['messages'] as List)
          .map((msg) => ConversationMessage.fromMap(msg))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }
} 