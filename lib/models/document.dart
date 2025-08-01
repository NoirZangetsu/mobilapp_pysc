class Document {
  final String id;
  final String userId;
  final String fileName;
  final String fileUrl;
  final String? title;
  final String? description;
  final DateTime uploadedAt;
  final DateTime? processedAt;
  final String status; // 'uploading', 'processing', 'completed', 'error'
  final String? errorMessage;
  final int? pageCount;
  final double? fileSize; // in MB
  final String? content; // Extracted text content

  Document({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.fileUrl,
    this.title,
    this.description,
    required this.uploadedAt,
    this.processedAt,
    required this.status,
    this.errorMessage,
    this.pageCount,
    this.fileSize,
    this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'title': title,
      'description': description,
      'uploadedAt': uploadedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'status': status,
      'errorMessage': errorMessage,
      'pageCount': pageCount,
      'fileSize': fileSize,
      'content': content,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      userId: map['userId'],
      fileName: map['fileName'],
      fileUrl: map['fileUrl'],
      title: map['title'],
      description: map['description'],
      uploadedAt: DateTime.parse(map['uploadedAt']),
      processedAt: map['processedAt'] != null 
          ? DateTime.parse(map['processedAt']) 
          : null,
      status: map['status'],
      errorMessage: map['errorMessage'],
      pageCount: map['pageCount'],
      fileSize: map['fileSize'],
      content: map['content'],
    );
  }

  Document copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? fileUrl,
    String? title,
    String? description,
    DateTime? uploadedAt,
    DateTime? processedAt,
    String? status,
    String? errorMessage,
    int? pageCount,
    double? fileSize,
    String? content,
  }) {
    return Document(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      processedAt: processedAt ?? this.processedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      content: content ?? this.content,
    );
  }
} 