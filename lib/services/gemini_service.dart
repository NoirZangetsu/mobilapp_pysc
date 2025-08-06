import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../config/env_config.dart';
import 'ai_optimization_service.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  
  // Enhanced educational system prompt with personalization
  static const String _systemPrompt = '''
# ÖĞRENME ASİSTANI - GELİŞMİŞ EĞİTİMSEL AI SİSTEMİ

## 🎓 KİMLİK VE ROL
Sen "Öğrenme Asistanı" adında gelişmiş bir eğitim yapay zeka asistanısın. Amacın öğrencilerin öğrenme sürecini optimize etmek ve en yüksek verimlilikte eğitim desteği sağlamaktır.

## 🧠 EĞİTİMSEL YETENEKLER
- **Kavram Açıklama**: Karmaşık kavramları basit ve anlaşılır şekilde açıklama
- **Pratik Örnekler**: Gerçek hayat uygulamaları ve örnekler sunma
- **Adım Adım Öğretim**: Karmaşık konuları mantıklı adımlara bölme
- **Görsel Destekli**: Görselleri eğitimsel açıdan analiz etme
- **Belge Analizi**: PDF ve belgeleri eğitimsel açıdan işleme
- **Öğrenme Hedefleri**: Net öğrenme hedefleri belirleme
- **Kişiselleştirilmiş Öğrenme**: Kullanıcının eğitim profiline göre uyarlama

## 📚 EĞİTİM STRATEJİLERİ
1. **Aktif Öğrenme**: Soru-cevap formatında etkileşimli öğretim
2. **Görsel Öğrenme**: Diyagram, grafik, tablo analizi ile öğretim
3. **Pratik Uygulama**: Gerçek hayat örnekleri ile öğretim
4. **Tekrar ve Pekiştirme**: Önemli kavramları vurgulama ve tekrarlama
5. **Değerlendirme**: Öğrencinin anlayışını test etme
6. **Kişiselleştirilmiş Yaklaşım**: Kullanıcının öğrenme stiline göre uyarlama

## 🎨 EĞİTİMSEL YANIT FORMATI
- **Açık ve Anlaşılır**: Karmaşık konuları basitleştirme
- **Yapılandırılmış**: Mantıklı sıralama ve düzenleme
- **Görsel Destekli**: Mümkün olduğunda görsel açıklama
- **Etkileşimli**: Öğrenciyi düşünmeye teşvik etme
- **Motivasyonel**: Öğrenmeyi destekleyici mesajlar
- **Kişiselleştirilmiş**: Kullanıcının seviyesine ve hedeflerine uygun

## 🔍 EĞİTİMSEL GÖRSEL ANALİZ
- **OCR**: Resimlerdeki metinleri okuma ve eğitimsel açıklama
- **Kavram Tanımlama**: Görseldeki kavramları tanımlama
- **Grafik Analizi**: Grafik, tablo, diyagram eğitimsel yorumlama
- **Matematiksel Formül**: Denklem ve formül adım adım açıklama
- **Doküman Analizi**: PDF ve belge içeriğini eğitimsel işleme

## 🎯 EĞİTİMSEL HEDEFLER
- **Kavramsal Anlama**: Derin kavram analizi ve açıklama
- **Pratik Uygulama**: Gerçek dünya bağlantıları kurma
- **Kritik Düşünme**: Analitik beceri geliştirme
- **Problem Çözme**: Yaratıcı problem çözme yaklaşımları
- **Öğrenme Motivasyonu**: Öğrenmeyi destekleyici yaklaşım
- **Kişisel Gelişim**: Kullanıcının güçlü ve zayıf alanlarına odaklanma

## 📊 EĞİTİMSEL PERFORMANS
- **Hızlı Yanıt**: Maksimum 2-3 saniye eğitimsel yanıt
- **Doğru Bilgi**: Güncel ve doğru eğitimsel bilgi aktarımı
- **Kişiselleştirme**: Öğrenci seviyesine uyarlama
- **Sürekli İyileştirme**: Her etkileşimde öğrenme
- **Adaptif Öğrenme**: Kullanıcının ilerlemesine göre ayarlama

## 🚀 EĞİTİMSEL ÖZELLİKLER
- **Context Awareness**: Önceki eğitimsel konuşmaları hatırlama
- **Progressive Learning**: Kademeli zorluk artırımı
- **Feedback Loop**: Öğrenci geri bildirimlerini değerlendirme
- **Adaptive Difficulty**: Öğrenci seviyesine göre ayarlama
- **Learning Objectives**: Net öğrenme hedefleri belirleme
- **Personalized Learning Path**: Kullanıcının profiline göre öğrenme yolu

## 📝 EĞİTİMSEL YANIT KALİTESİ
1. **Doğruluk**: %99+ eğitimsel bilgi doğruluğu
2. **Güncellik**: En güncel eğitimsel bilgiler
3. **Kapsamlılık**: Detaylı ve eksiksiz eğitimsel açıklama
4. **Anlaşılırlık**: Her seviyede öğrenci için uygun
5. **Pratik Değer**: Gerçek hayatta uygulanabilir eğitim
6. **Kişiselleştirme**: Kullanıcının ihtiyaçlarına özel

## 🎓 EĞİTİMSEL MODÜLLER
- **Kavram Açıklama**: Temel kavramların detaylı açıklaması
- **İleri Seviye Analiz**: Derinlemesine eğitimsel analiz
- **Pratik Uygulama**: Gerçek dünya örnekleri
- **Değerlendirme**: Öğrenme kontrolü ve geri bildirim
- **Flashcard Oluşturma**: Eğitimsel kartlar oluşturma
- **Podcast Oluşturma**: Eğitimsel sesli içerik
- **Kişiselleştirilmiş Öneriler**: Kullanıcının profiline göre öneriler

## 🔧 EĞİTİMSEL OPTİMİZASYON
- **Token Efficiency**: Maksimum verimlilik için token optimizasyonu
- **Context Management**: Akıllı eğitimsel context yönetimi
- **Response Caching**: Tekrarlanan eğitimsel sorgular için cache
- **Error Recovery**: Hata durumlarında otomatik kurtarma
- **Personalization Engine**: Kullanıcı profili analizi ve uyarlama

## 📈 SÜREKLİ EĞİTİMSEL İYİLEŞTİRME
- **Performance Monitoring**: Eğitimsel yanıt kalitesi takibi
- **Student Feedback**: Öğrenci geri bildirimleri
- **Model Updates**: Sürekli eğitimsel model güncellemeleri
- **Feature Enhancement**: Yeni eğitimsel özellik ekleme
- **Personalization Learning**: Kullanıcı davranışlarından öğrenme

## 👤 KİŞİSELLEŞTİRME YÖNERGELERİ
- Kullanıcının eğitim seviyesine uygun dil kullan
- Öğrenme stilini dikkate al (görsel, işitsel, kinestetik)
- Güçlü alanları destekle ve zayıf alanları geliştir
- Çalışma konularına odaklan
- Öğrenme hedeflerine uygun içerik sun
- Günlük çalışma süresine uygun öneriler ver
- Çalışma ortamına uygun stratejiler öner
- Tercih edilen ses stilini kullan

Bu sistem, öğrencilerin öğrenme deneyimini maksimuma çıkarmak için optimize edilmiştir.
''';

  // AI Optimization Service
  final AIOptimizationService _optimizationService = AIOptimizationService();

  // Cache for repeated requests
  final Map<String, String> _responseCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  // Context optimization
  static const int _maxHistoryLength = 10;
  static const int _maxContextTokens = 8000;

  // Enhanced educational response generation with caching and optimization
  Future<String> generateResponse(String userMessage, List<ConversationMessage> history) async {
    return await _generateOptimizedEducationalResponse(userMessage, history, null, null);
  }

  Future<String> generateResponseWithImage(
    String userMessage, 
    List<ConversationMessage> history,
    File imageFile,
  ) async {
    return await _generateOptimizedEducationalResponse(userMessage, history, imageFile, null);
  }

  Future<String> generateResponseWithDocument(
    String userMessage, 
    List<ConversationMessage> history,
    String documentContent,
  ) async {
    return await _generateOptimizedEducationalResponse(userMessage, history, null, documentContent);
  }

  Future<String> generateResponseWithImageAndDocument(
    String userMessage, 
    List<ConversationMessage> history,
    File imageFile,
    String documentContent,
  ) async {
    return await _generateOptimizedEducationalResponse(userMessage, history, imageFile, documentContent);
  }

  // Generate educational content (flashcards, podcasts, summaries)
  Future<String> generateEducationalContent(
    String content,
    String topic,
    String contentType, // 'flashcard', 'podcast', 'summary'
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      if (!EnvConfig.isGeminiConfigured) {
        throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY environment variable.');
      }

      String prompt;
      switch (contentType) {
        case 'flashcard':
          prompt = _optimizationService.generateFlashcardPrompt(content, topic);
          break;
        case 'podcast':
          prompt = _optimizationService.generatePodcastPrompt(content, topic);
          break;
        case 'summary':
          prompt = _optimizationService.extractEducationalContent(content);
          break;
        default:
          prompt = _optimizationService.analyzeEducationalContent(content);
      }

      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [{'text': _systemPrompt}]
          },
          {
            'role': 'user',
            'parts': [{'text': prompt}]
          }
        ],
        'generationConfig': {
          'temperature': 0.8,
          'topK': 50,
          'topP': 0.9,
          'maxOutputTokens': 4096,
          'candidateCount': 1,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await _executeRequestWithRetry(requestBody);
      String processedResponse = _processResponse(response);
      processedResponse = _optimizationService.optimizeEducationalResponse(processedResponse);
      
      // Log performance and quality metrics
      final qualityScore = _optimizationService.assessEducationalResponseQuality(processedResponse);
      _logPerformance('success', stopwatch.elapsedMilliseconds, qualityScore: qualityScore);
      
      return processedResponse;

    } catch (e) {
      _logPerformance('error', stopwatch.elapsedMilliseconds, error: e.toString());
      throw Exception('Failed to generate educational content: $e');
    }
  }

  Future<String> _generateOptimizedEducationalResponse(
    String userMessage, 
    List<ConversationMessage> history,
    File? imageFile,
    String? documentContent,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(userMessage, history, imageFile, documentContent);
      final cachedResponse = _getCachedResponse(cacheKey);
      if (cachedResponse != null) {
        _logPerformance('cache_hit', stopwatch.elapsedMilliseconds);
        return cachedResponse;
      }

      // Validate configuration
      if (!EnvConfig.isGeminiConfigured) {
        throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY environment variable.');
      }

      // Optimize context using AI optimization service
      final optimizedHistory = _optimizationService.optimizeContext(history);
      final optimizedDocumentContent = _optimizationService.optimizeDocumentContent(documentContent);

      // Enhance user message based on input type for educational purposes
      String enhancedUserMessage = userMessage;
      if (imageFile != null && documentContent != null) {
        enhancedUserMessage = _optimizationService.enhanceMultimodalQuestion(userMessage);
      } else if (imageFile != null) {
        enhancedUserMessage = _optimizationService.enhanceImageQuestion(userMessage);
      } else if (documentContent != null) {
        enhancedUserMessage = _optimizationService.enhanceQuestionWithContext(userMessage, documentContent);
      }

      // Prepare request with enhanced educational configuration
      final requestBody = await _prepareOptimizedEducationalRequest(
        enhancedUserMessage, 
        optimizedHistory, 
        imageFile, 
        optimizedDocumentContent,
      );

      // Execute request with retry logic
      final response = await _executeRequestWithRetry(requestBody);
      
      // Process and enhance educational response
      String processedResponse = _processResponse(response);
      processedResponse = _optimizationService.optimizeEducationalResponse(processedResponse);
      processedResponse = _optimizationService.enhanceEducationalResponseWithElements(processedResponse);
      
      // Cache the enhanced educational response
      _cacheResponse(cacheKey, processedResponse);
      
      // Log performance and educational quality metrics
      final qualityScore = _optimizationService.assessEducationalResponseQuality(processedResponse);
      _logPerformance('success', stopwatch.elapsedMilliseconds, qualityScore: qualityScore);
      
      return processedResponse;

    } catch (e) {
      _logPerformance('error', stopwatch.elapsedMilliseconds, error: e.toString());
      throw Exception('Failed to generate educational response: $e');
    }
  }

  String _generateCacheKey(
    String userMessage, 
    List<ConversationMessage> history,
    File? imageFile,
    String? documentContent,
  ) {
    final keyComponents = [
      userMessage,
      history.map((msg) => '${msg.isUser ? "user" : "ai"}:${msg.content}').join('|'),
      imageFile?.path ?? '',
      documentContent ?? '',
    ];
    return base64Encode(utf8.encode(keyComponents.join('||')));
  }

  String? _getCachedResponse(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
      return _responseCache[cacheKey];
    }
    // Clean expired cache
    _responseCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    return null;
  }

  void _cacheResponse(String cacheKey, String response) {
    _responseCache[cacheKey] = response;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Clean old cache entries if too many
    if (_responseCache.length > 50) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _responseCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  Future<Map<String, dynamic>> _prepareOptimizedEducationalRequest(
    String userMessage,
    List<ConversationMessage> history,
    File? imageFile,
    String? documentContent,
  ) async {
    final List<Map<String, dynamic>> contents = [];
    
    // Generate optimized educational system prompt
    final optimizedSystemPrompt = _optimizationService.generateOptimizedEducationalPrompt(
      _systemPrompt,
      userMessage: userMessage,
      history: history,
      documentContent: documentContent,
      imageFile: imageFile,
    );
    
    // Add enhanced educational system prompt
    contents.add({
      'role': 'user',
      'parts': [{'text': optimizedSystemPrompt}]
    });
    
    // Add optimized conversation history
    for (final message in history) {
      contents.add({
        'role': message.isUser ? 'user' : 'model',
        'parts': [{'text': message.content}]
      });
    }
    
    // Prepare user message with multimodal content
    final List<Map<String, dynamic>> userParts = [];
    userParts.add({'text': userMessage});
    
    // Add image if provided
    if (imageFile != null) {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType = _getMimeType(imageFile.path);
      
      userParts.add({
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Image
        }
      });
    }
    
    // Add document content if provided
    if (documentContent != null) {
      userParts.add({'text': '\n\n📄 EĞİTİMSEL İÇERİK:\n$documentContent'});
    }
    
    contents.add({
      'role': 'user',
      'parts': userParts
    });
    
    // Get optimized educational generation configuration
    final optimizedConfig = _optimizationService.optimizeEducationalRequestConfig(
      userMessage: userMessage,
      history: history,
      imageFile: imageFile,
      documentContent: documentContent,
    );
    
    // Enhanced educational generation configuration
    return {
      'contents': contents,
      'generationConfig': optimizedConfig,
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };
  }

  Future<Map<String, dynamic>> _executeRequestWithRetry(Map<String, dynamic> requestBody) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl?key=${EnvConfig.getGeminiApiKey()}'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'LearningAssistant/1.0',
          },
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 30));
        
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else if (response.statusCode == 429) {
          // Rate limit - wait longer
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        } else {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        lastException = Exception('Attempt $attempt failed: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }
    
    throw lastException ?? Exception('All retry attempts failed');
  }

  String _processResponse(Map<String, dynamic> responseData) {
    final candidates = responseData['candidates'] as List;
    
    if (candidates.isNotEmpty) {
      final content = candidates.first['content'];
      final parts = content['parts'] as List;
      
      if (parts.isNotEmpty) {
        String response = parts.first['text'] as String;
        
        // Post-process response for better educational quality
        response = _postProcessEducationalResponse(response);
        
        return response;
      }
    }
    
    throw Exception('No valid response from Gemini API');
  }

  String _postProcessEducationalResponse(String response) {
    // Remove unnecessary whitespace
    response = response.trim();
    
    // Ensure proper formatting
    if (!response.endsWith('.') && !response.endsWith('!') && !response.endsWith('?')) {
      response += '.';
    }
    
    // Add educational context if missing
    if (!response.contains('öğrenme') && !response.contains('eğitim') && !response.contains('bilgi')) {
      response += '\n\n💡 **Öğrenme İpucu:** Bu bilgiyi daha iyi anlamak için pratik örnekler üzerinde çalışabilirsin.';
    }
    
    return response;
  }

  void _logPerformance(String status, int duration, {String? error, double? qualityScore}) {
    // Performance logging removed for user simplicity
  }

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
        return 'image/tiff';
      default:
        return 'image/jpeg';
    }
  }

  // Clear cache and metrics
  void clearCache() {
    _responseCache.clear();
    _cacheTimestamps.clear();
  }

  void clearMetrics() {
    // Metrics clearing removed for user simplicity
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cache_size': _responseCache.length,
      'oldest_entry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
      'newest_entry': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  // Get optimization service
  AIOptimizationService get optimizationService => _optimizationService;
} 