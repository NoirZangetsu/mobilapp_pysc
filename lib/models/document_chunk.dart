class DocumentChunk {
  final String id;
  final String documentId;
  final String content;
  final List<double> embedding;
  final int pageNumber;
  final int chunkIndex;

  DocumentChunk({
    required this.id,
    required this.documentId,
    required this.content,
    required this.embedding,
    required this.pageNumber,
    required this.chunkIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'content': content,
      'embedding': embedding,
      'pageNumber': pageNumber,
      'chunkIndex': chunkIndex,
    };
  }

  factory DocumentChunk.fromMap(Map<String, dynamic> map) {
    return DocumentChunk(
      id: map['id'],
      documentId: map['documentId'],
      content: map['content'],
      embedding: List<double>.from(map['embedding']),
      pageNumber: map['pageNumber'],
      chunkIndex: map['chunkIndex'],
    );
  }
} 