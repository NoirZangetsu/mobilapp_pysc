import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isUser;
  final String? audioUrl;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isUser,
    this.audioUrl,
    this.metadata,
  });

  // Convert ChatMessage to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isUser': isUser,
      'audioUrl': audioUrl,
      'metadata': metadata,
    };
  }

  // Create ChatMessage from Firestore Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isUser: map['isUser'] ?? false,
      audioUrl: map['audioUrl'],
      metadata: map['metadata'],
    );
  }

  // Create ChatMessage with auto-generated ID
  factory ChatMessage.create({
    required String content,
    required bool isUser,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      timestamp: DateTime.now(),
      isUser: isUser,
      audioUrl: audioUrl,
      metadata: metadata,
    );
  }

  // Copy with method for updating specific fields
  ChatMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isUser,
    String? audioUrl,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isUser: isUser ?? this.isUser,
      audioUrl: audioUrl ?? this.audioUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, timestamp: $timestamp, isUser: $isUser)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.isUser == isUser;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        timestamp.hashCode ^
        isUser.hashCode;
  }
} 