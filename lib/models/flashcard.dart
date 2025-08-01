class Flashcard {
  final String id;
  final String deckId;
  final String question;
  final String answer;
  final DateTime createdAt;
  final int? difficulty;
  final int? reviewCount;
  final DateTime? lastReviewed;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    required this.createdAt,
    this.difficulty,
    this.reviewCount,
    this.lastReviewed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty,
      'reviewCount': reviewCount,
      'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      deckId: map['deckId'],
      question: map['question'],
      answer: map['answer'],
      createdAt: DateTime.parse(map['createdAt']),
      difficulty: map['difficulty'],
      reviewCount: map['reviewCount'],
      lastReviewed: map['lastReviewed'] != null 
          ? DateTime.parse(map['lastReviewed']) 
          : null,
    );
  }

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    DateTime? createdAt,
    int? difficulty,
    int? reviewCount,
    DateTime? lastReviewed,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }
}

class FlashcardDeck {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? sourceType;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime? lastStudied;
  final int cardCount;
  final List<Flashcard> cards;

  const FlashcardDeck({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.sourceType,
    this.sourceId,
    required this.createdAt,
    this.lastStudied,
    required this.cardCount,
    required this.cards,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'createdAt': createdAt.toIso8601String(),
      'lastStudied': lastStudied?.toIso8601String(),
      'cardCount': cardCount,
      'cards': cards.map((card) => card.toMap()).toList(),
    };
  }

  factory FlashcardDeck.fromMap(Map<String, dynamic> map) {
    return FlashcardDeck(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      sourceType: map['sourceType'],
      sourceId: map['sourceId'],
      createdAt: DateTime.parse(map['createdAt']),
      lastStudied: map['lastStudied'] != null 
          ? DateTime.parse(map['lastStudied']) 
          : null,
      cardCount: map['cardCount'],
      cards: (map['cards'] as List)
          .map((card) => Flashcard.fromMap(card))
          .toList(),
    );
  }

  FlashcardDeck copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? sourceType,
    String? sourceId,
    DateTime? createdAt,
    DateTime? lastStudied,
    int? cardCount,
    List<Flashcard>? cards,
  }) {
    return FlashcardDeck(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      createdAt: createdAt ?? this.createdAt,
      lastStudied: lastStudied ?? this.lastStudied,
      cardCount: cardCount ?? this.cardCount,
      cards: cards ?? this.cards,
    );
  }
} 