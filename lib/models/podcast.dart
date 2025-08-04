class Podcast {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? sourceType; // 'manual', 'document', 'topic'
  final String? sourceId; // document ID or topic name
  final String audioUrl;
  final Duration duration;
  final DateTime createdAt;
  final DateTime? lastListened;
  final int? listenCount;
  final String? voiceStyle; // 'energetic', 'calm', 'professional', 'friendly'
  final String? language; // 'tr-TR', 'en-US', etc.
  final String? podcastType; // 'educational', 'story', 'news', 'interview'
  final String? script; // Podcast script for reference

  Podcast({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.sourceType,
    this.sourceId,
    required this.audioUrl,
    required this.duration,
    required this.createdAt,
    this.lastListened,
    this.listenCount,
    this.voiceStyle,
    this.language,
    this.podcastType,
    this.script,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'createdAt': createdAt.toIso8601String(),
      'lastListened': lastListened?.toIso8601String(),
      'listenCount': listenCount,
      'voiceStyle': voiceStyle,
      'language': language,
      'podcastType': podcastType,
      'script': script,
    };
  }

  factory Podcast.fromMap(Map<String, dynamic> map) {
    return Podcast(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      sourceType: map['sourceType'],
      sourceId: map['sourceId'],
      audioUrl: map['audioUrl'],
      duration: Duration(seconds: map['duration']),
      createdAt: DateTime.parse(map['createdAt']),
      lastListened: map['lastListened'] != null 
          ? DateTime.parse(map['lastListened']) 
          : null,
      listenCount: map['listenCount'],
      voiceStyle: map['voiceStyle'],
      language: map['language'],
      podcastType: map['podcastType'],
      script: map['script'],
    );
  }

  Podcast copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? sourceType,
    String? sourceId,
    String? audioUrl,
    Duration? duration,
    DateTime? createdAt,
    DateTime? lastListened,
    int? listenCount,
    String? voiceStyle,
    String? language,
    String? podcastType,
    String? script,
  }) {
    return Podcast(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      lastListened: lastListened ?? this.lastListened,
      listenCount: listenCount ?? this.listenCount,
      voiceStyle: voiceStyle ?? this.voiceStyle,
      language: language ?? this.language,
      podcastType: podcastType ?? this.podcastType,
      script: script ?? this.script,
    );
  }
} 