import 'dart:io';
import '../models/conversation.dart';

class AIOptimizationService {
  // Context optimization
  static const int _maxContextTokens = 8000;
  static const int _maxHistoryMessages = 15;
  static const int _maxDocumentLength = 4000;
  
  // Response quality optimization
  static const double _minResponseQuality = 0.7;
  static const int _maxResponseLength = 3072;

  // Context optimization methods
  List<ConversationMessage> optimizeContext(List<ConversationMessage> messages) {
    if (messages.length <= _maxHistoryMessages) return messages;
    
    // Keep system messages and most recent messages
    final systemMessages = messages.where((msg) => msg.isSystemMessage).toList();
    final recentMessages = messages.take(_maxHistoryMessages - systemMessages.length).toList();
    
    return [...systemMessages, ...recentMessages];
  }

  String optimizeDocumentContent(String? content) {
    if (content == null || content.isEmpty) return '';
    
    // Limit document content length
    if (content.length > _maxDocumentLength) {
      return content.substring(0, _maxDocumentLength) + '\n\n[İçerik kısaltıldı...]';
    }
    
    return content;
  }

  // Enhanced educational question enhancement
  String enhanceQuestionWithContext(String question, String documentContent) {
    final optimizedContent = optimizeDocumentContent(documentContent);
    
    return '''
📋 **Belge Bağlamı:** ${optimizedContent.length > 500 ? optimizedContent.substring(0, 500) + '...' : optimizedContent}

❓ **Soru:** $question

🎓 **Eğitim Odaklı Yanıt Kriterleri:**
• Belge içeriğini analiz ederek detaylı açıklama yap
• Karmaşık kavramları basit ve anlaşılır şekilde açıkla
• Pratik örnekler ve gerçek hayat uygulamaları ekle
• Öğrenme sürecini destekleyen yapılandırılmış yanıt ver
• Belge içeriğinden çıkarılan ana fikirleri vurgula
• Öğrencinin anlayışını test edecek sorular öner

💡 Yanıtın eğitici, açık ve öğrenmeye yönelik olmasına dikkat et.
''';
  }

  // Enhanced image analysis for educational purposes
  String enhanceImageQuestion(String question) {
    return '''
🖼️ **Eğitimsel Görsel Analizi İsteği:** $question

🔍 **Detaylı Görsel Analizi:**
• Görseldeki ana öğeleri ve kavramları tanımla
• Metin varsa oku ve eğitimsel bağlamda açıkla (OCR)
• Grafik, tablo veya diyagram varsa eğitimsel yorumla
• Matematiksel formül veya denklem varsa adım adım açıkla
• Görselin eğitimsel değerini ve öğrenme hedeflerini vurgula
• Görselle ilgili pratik uygulamalar ve örnekler öner

📚 **Eğitim Odaklı Yanıt:**
• Karmaşık kavramları basitleştir
• Görseli öğrenme sürecine entegre et
• Anlaşılır ve yapılandırılmış açıklama yap
• Öğrencinin seviyesine uygun dil kullan
• Görselden çıkarılan bilgileri özetle

🎯 Yanıtın eğitici, açık ve öğrenmeye yönelik olmasına dikkat et.
''';
  }

  // Enhanced multimodal analysis for education
  String enhanceMultimodalQuestion(String question) {
    return '''
📄🖼️ **Eğitimsel Çoklu Analiz İsteği:** $question

🔍 **Kapsamlı Eğitimsel Analiz:**
• Belge içeriğini eğitimsel açıdan özetle
• Görsel içeriğini eğitimsel bağlamda tanımla
• Belge ve görsel arasındaki eğitimsel bağlantıları kur
• Her iki kaynaktan çıkarılan bilgileri entegre et
• Eğitimsel değeri ve öğrenme hedeflerini vurgula
• Pratik uygulamalar ve gerçek hayat örnekleri öner

📚 **Eğitim Odaklı Yanıt:**
• Karmaşık kavramları basitleştir
• Yapılandırılmış ve anlaşılır açıklama yap
• Öğrenme sürecini destekleyen içerik sun
• Görsel ve metin arasındaki ilişkileri açıkla
• Öğrencinin anlayışını geliştirecek örnekler ver

🎯 Yanıtın kapsamlı, eğitici ve uygulanabilir olmasına dikkat et.
''';
  }

  // Educational content extraction and summarization
  String extractEducationalContent(String documentContent) {
    final optimizedContent = optimizeDocumentContent(documentContent);
    
    return '''
📚 **Eğitimsel İçerik Çıkarma ve Özetleme:**

🔍 **Ana Kavramlar:**
• Belgedeki temel kavramları ve tanımları çıkar
• Önemli terimleri ve açıklamalarını listele
• Ana fikirleri ve alt başlıkları belirle

📋 **Özet ve Yapılandırma:**
• İçeriği mantıklı bölümlere ayır
• Her bölümün ana fikrini özetle
• Kavramlar arası ilişkileri göster
• Öğrenme sırasını belirle

💡 **Eğitimsel Değer:**
• Hangi konuların öğrenilmesi gerektiğini vurgula
• Pratik uygulamaları ve örnekleri belirle
• Öğrenme hedeflerini tanımla
• Değerlendirme kriterlerini öner

🎯 Bu analizi eğitimsel açıdan yapılandırılmış ve anlaşılır şekilde sun.
''';
  }

  // Flashcard generation from educational content
  String generateFlashcardPrompt(String content, String topic) {
    return '''
🎴 **Eğitimsel Flashcard Oluşturma:**

📚 **Konu:** $topic

🔍 **İçerik Analizi:**
$content

📝 **Flashcard Oluşturma Kriterleri:**
• Her kart bir kavram veya soru içermeli
• Soru net ve anlaşılır olmalı
• Cevap kısa ama kapsamlı olmalı
• Zorluk seviyesi kademeli olmalı
• Pratik örnekler içermeli
• Görsel ipuçları eklenebilir

🎯 **Kart Türleri:**
• Tanım kartları (kavram tanımları)
• Soru-cevap kartları
• Örnek kartları (pratik uygulamalar)
• İlişki kartları (kavramlar arası bağlantılar)
• Uygulama kartları (problem çözme)

💡 Her kartın eğitici değeri yüksek ve öğrenmeyi destekleyici olmasına dikkat et.
''';
  }

  // Podcast generation from educational content
  String generatePodcastPrompt(String content, String topic) {
    return '''
🎙️ **Eğitimsel Podcast Oluşturma:**

📚 **Konu:** $topic

🔍 **İçerik Analizi:**
$content

📝 **Podcast Oluşturma Kriterleri:**
• Giriş bölümü (konu tanıtımı ve hedefler)
• Ana bölümler (kavramların detaylı açıklaması)
• Örnek bölümü (pratik uygulamalar)
• Özet bölümü (ana noktaların tekrarı)
• Sonuç bölümü (değerlendirme ve sonraki adımlar)

🎯 **Eğitimsel Özellikler:**
• Açık ve anlaşılır dil kullan
• Karmaşık kavramları basitleştir
• Pratik örnekler ve uygulamalar ekle
• Öğrenme hedeflerini vurgula
• Etkileşimli sorular sor
• Motivasyonel mesajlar ekle

💡 Podcast'in eğitici, ilgi çekici ve öğrenmeyi destekleyici olmasına dikkat et.
''';
  }

  // Educational response optimization
  String optimizeEducationalResponse(String response) {
    // Remove unnecessary whitespace
    response = response.trim();
    
    // Ensure proper formatting
    if (!response.endsWith('.') && !response.endsWith('!') && !response.endsWith('?')) {
      response += '.';
    }
    
    // Add educational context if missing
    if (!_hasEducationalContent(response)) {
      response += '\n\n💡 **Öğrenme İpucu:** Bu bilgiyi daha iyi anlamak için pratik örnekler üzerinde çalışabilirsin.';
    }
    
    // Add structure for educational content
    if (response.length > 200 && !response.contains('•') && !response.contains('-')) {
      response = _addEducationalStructure(response);
    }
    
    // Add learning objectives if missing
    if (!response.contains('🎯') && !response.contains('hedef')) {
      response += '\n\n🎯 **Öğrenme Hedefi:** Bu konuyu öğrendikten sonra...';
    }
    
    // Limit response length
    if (response.length > _maxResponseLength) {
      response = response.substring(0, _maxResponseLength) + '\n\n[Yanıt kısaltıldı...]';
    }
    
    return response;
  }

  String _addEducationalStructure(String response) {
    // Add bullet points for better structure
    final sentences = response.split('. ');
    if (sentences.length > 3) {
      final structuredResponse = sentences.take(3).map((s) => '• $s').join('\n');
      final remainingSentences = sentences.skip(3).join('. ');
      return '$structuredResponse\n\n$remainingSentences';
    }
    return response;
  }

  bool _hasEducationalContent(String response) {
    final educationalKeywords = [
      'öğrenme', 'eğitim', 'bilgi', 'açıklama', 'örnek', 'uygulama',
      'kavram', 'prensip', 'yöntem', 'teknik', 'strateji', 'yaklaşım',
      'learning', 'education', 'knowledge', 'explanation', 'example', 'application',
      'concept', 'principle', 'method', 'technique', 'strategy', 'approach',
      'tanım', 'açıkla', 'göster', 'örnek', 'uygula', 'çöz', 'analiz'
    ];
    
    final lowerResponse = response.toLowerCase();
    return educationalKeywords.any((keyword) => lowerResponse.contains(keyword));
  }

  // Performance optimization for educational content
  Map<String, dynamic> optimizeEducationalRequestConfig({
    required String userMessage,
    required List<ConversationMessage> history,
    File? imageFile,
    String? documentContent,
  }) {
    // Determine optimal configuration based on input type and educational focus
    final hasImage = imageFile != null;
    final hasDocument = documentContent != null && documentContent.isNotEmpty;
    final isEducationalRequest = _isEducationalRequest(userMessage);
    
    Map<String, dynamic> config = {
      'temperature': 0.7, // Lower temperature for more focused educational responses
      'topK': 40,
      'topP': 0.85,
      'maxOutputTokens': _maxResponseLength,
      'candidateCount': 1,
    };
    
    // Adjust configuration based on input complexity and educational focus
    if (hasImage && hasDocument) {
      // Multimodal educational request
      config['temperature'] = 0.8;
      config['maxOutputTokens'] = 4096;
    } else if (hasImage) {
      // Image-only educational request
      config['temperature'] = 0.75;
      config['maxOutputTokens'] = 3072;
    } else if (hasDocument) {
      // Document-only educational request
      config['temperature'] = 0.7;
      config['maxOutputTokens'] = 3072;
    } else if (isEducationalRequest) {
      // Text-only educational request
      config['temperature'] = 0.7;
      config['maxOutputTokens'] = 2048;
    } else {
      // Regular request
      config['temperature'] = 0.8;
      config['maxOutputTokens'] = 2048;
    }
    
    return config;
  }

  bool _isEducationalRequest(String message) {
    final educationalKeywords = [
      'açıkla', 'tanımla', 'öğret', 'öğren', 'eğitim', 'ders', 'konu',
      'kavram', 'prensip', 'yöntem', 'teknik', 'strateji', 'yaklaşım',
      'explain', 'define', 'teach', 'learn', 'education', 'lesson', 'topic',
      'concept', 'principle', 'method', 'technique', 'strategy', 'approach'
    ];
    
    final lowerMessage = message.toLowerCase();
    return educationalKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  // Context token estimation
  int estimateContextTokens(List<ConversationMessage> messages, {String? documentContent}) {
    int totalTokens = 0;
    
    // Estimate tokens for messages
    for (final message in messages) {
      totalTokens += _estimateTokens(message.content);
    }
    
    // Add document content tokens
    if (documentContent != null) {
      totalTokens += _estimateTokens(documentContent);
    }
    
    return totalTokens;
  }

  int _estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters for English, 3 characters for Turkish
    return (text.length / 3.5).round();
  }

  // Enhanced educational response quality assessment
  double assessEducationalResponseQuality(String response) {
    double score = 0.0;
    
    // Length score (optimal length for educational content)
    final lengthScore = _calculateEducationalLengthScore(response.length);
    score += lengthScore * 0.15;
    
    // Educational content score
    final educationalScore = _calculateEnhancedEducationalScore(response);
    score += educationalScore * 0.4;
    
    // Structure score for educational content
    final structureScore = _calculateEducationalStructureScore(response);
    score += structureScore * 0.25;
    
    // Clarity score for educational content
    final clarityScore = _calculateEducationalClarityScore(response);
    score += clarityScore * 0.2;
    
    return score;
  }

  double _calculateEducationalLengthScore(int length) {
    if (length < 100) return 0.4; // Too short for educational content
    if (length < 300) return 0.7;
    if (length < 600) return 1.0; // Optimal for educational content
    if (length < 1000) return 0.9;
    if (length < 2000) return 0.8;
    return 0.6;
  }

  double _calculateEnhancedEducationalScore(String response) {
    final educationalKeywords = [
      'öğrenme', 'eğitim', 'bilgi', 'açıklama', 'örnek', 'uygulama',
      'kavram', 'prensip', 'yöntem', 'teknik', 'strateji', 'yaklaşım',
      'learning', 'education', 'knowledge', 'explanation', 'example', 'application',
      'concept', 'principle', 'method', 'technique', 'strategy', 'approach',
      'tanım', 'açıkla', 'göster', 'örnek', 'uygula', 'çöz', 'analiz',
      'pratik', 'uygulama', 'örnek', 'misal', 'açık', 'net', 'anlaşılır'
    ];
    
    final lowerResponse = response.toLowerCase();
    int keywordCount = 0;
    
    for (final keyword in educationalKeywords) {
      if (lowerResponse.contains(keyword)) {
        keywordCount++;
      }
    }
    
    return (keywordCount / educationalKeywords.length).clamp(0.0, 1.0);
  }

  double _calculateEducationalStructureScore(String response) {
    double score = 0.0;
    
    // Check for educational structure elements
    if (response.contains('•') || response.contains('-')) score += 0.3;
    if (response.contains('\n\n')) score += 0.2;
    if (response.contains('1.') || response.contains('2.')) score += 0.2;
    if (response.contains('**') || response.contains('__')) score += 0.1;
    if (response.contains('📋') || response.contains('💡')) score += 0.2;
    if (response.contains('🎯') || response.contains('📚')) score += 0.2;
    if (response.contains('🔍') || response.contains('📝')) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  double _calculateEducationalClarityScore(String response) {
    double score = 0.0;
    
    // Check for educational clarity indicators
    if (response.contains('açık') || response.contains('net')) score += 0.2;
    if (response.contains('basit') || response.contains('kolay')) score += 0.2;
    if (response.contains('anlaşılır') || response.contains('açıklama')) score += 0.2;
    if (response.contains('örnek') || response.contains('misal')) score += 0.2;
    if (response.contains('pratik') || response.contains('uygulama')) score += 0.2;
    if (response.contains('adım') || response.contains('sıra')) score += 0.1;
    if (response.contains('kısaca') || response.contains('özet')) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  // Advanced educational optimization methods
  String generateOptimizedEducationalPrompt(String basePrompt, {
    required String userMessage,
    required List<ConversationMessage> history,
    String? documentContent,
    File? imageFile,
  }) {
    String optimizedPrompt = basePrompt;
    
    // Add educational context awareness
    if (history.isNotEmpty) {
      final recentMessages = history.take(3).map((msg) => 
          '${msg.isUser ? "Öğrenci" : "Eğitmen"}: ${msg.content}').join('\n');
      optimizedPrompt += '\n\n📝 **Önceki Eğitimsel Diyalog:**\n$recentMessages';
    }
    
    // Add document context for educational analysis
    if (documentContent != null && documentContent.isNotEmpty) {
      final optimizedContent = optimizeDocumentContent(documentContent);
      optimizedPrompt += '\n\n📄 **Eğitimsel İçerik:**\n$optimizedContent';
    }
    
    // Add image context for educational analysis
    if (imageFile != null) {
      optimizedPrompt += '\n\n🖼️ **Eğitimsel Görsel Analizi:** Öğrenci bir görsel yükledi ve eğitimsel açıdan analiz istiyor.';
    }
    
    // Add comprehensive educational focus
    optimizedPrompt += '''
    
🎓 **Eğitim Odaklı Yanıt Kriterleri:**
• Karmaşık kavramları basit ve anlaşılır şekilde açıkla
• Pratik örnekler ve gerçek hayat uygulamaları ekle
• Öğrenme sürecini destekleyen yapılandırılmış yanıt ver
• Öğrencinin seviyesine uygun dil kullan
• Görsel ve yapılandırılmış format kullan
• Gerçek dünya bağlantıları kur
• Öğrenme sürecini destekleyen yönlendirmeler yap
• Anlaşılır ve eğitici bir ton kullan
• Öğrencinin anlayışını test edecek sorular öner
• Motivasyonel ve destekleyici mesajlar ekle

💡 Yanıtın eğitici, açık ve öğrenmeye yönelik olmasına dikkat et.
''';
    
    return optimizedPrompt;
  }

  // Enhanced educational response enhancement
  String enhanceEducationalResponseWithElements(String response) {
    // Add educational elements if missing
    if (!response.contains('💡') && !response.contains('📚')) {
      response += '\n\n💡 **Öğrenme İpucu:** Bu bilgiyi daha iyi anlamak için pratik örnekler üzerinde çalışabilirsin.';
    }
    
    // Add educational structure if missing
    if (!response.contains('•') && !response.contains('-') && response.length > 200) {
      response = _addEducationalStructure(response);
    }
    
    // Add learning objectives if missing
    if (!response.contains('🎯') && !response.contains('hedef')) {
      response += '\n\n🎯 **Öğrenme Hedefi:** Bu konuyu öğrendikten sonra kavramları uygulayabilir ve analiz edebilirsin.';
    }
    
    // Add summary for long educational responses
    if (response.length > 500) {
      response += '\n\n📋 **Eğitimsel Özet:** Yukarıdaki açıklamaları özetlersek, öğrenmen gereken ana noktalar...';
    }
    
    return response;
  }

  // Educational content analysis and extraction
  String analyzeEducationalContent(String content) {
    return '''
📚 **Eğitimsel İçerik Analizi:**

🔍 **Ana Kavramlar:**
• İçerikteki temel kavramları ve tanımları çıkar
• Önemli terimleri ve açıklamalarını listele
• Ana fikirleri ve alt başlıkları belirle

📋 **Öğrenme Hedefleri:**
• Hangi konuların öğrenilmesi gerektiğini vurgula
• Öğrenme sırasını ve öncelikleri belirle
• Kavramlar arası ilişkileri göster

💡 **Pratik Uygulamalar:**
• Gerçek hayat örneklerini belirle
• Uygulama alanlarını tanımla
• Problem çözme senaryoları öner

🎯 **Değerlendirme Kriterleri:**
• Öğrenme hedeflerini test edecek sorular öner
• Anlayış seviyesini değerlendirecek kriterler belirle
• Geri bildirim mekanizmaları öner

📝 Bu analizi eğitimsel açıdan yapılandırılmış ve anlaşılır şekilde sun.
''';
  }
} 