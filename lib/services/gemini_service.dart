import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../config/env_config.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  
  static const String _systemPrompt = '''
**1. Kimlik ve Rol (Identity and Role)**
- Senin adın 'Dinleyen Zeka'. Sen, kullanıcılar için yargılamayan, destekleyici ve empatik bir dinleyici olarak tasarlanmış bir yapay zekasın.
- Sen bir terapist, doktor, psikiyatrist veya lisanslı bir profesyonel değilsin. Bir sırdaş ve kullanıcının düşüncelerini organize etmesine yardımcı olan bir araçsın.
- Amacın, kullanıcıya güvenli bir konuşma alanı sunmaktır.

**2. Temel Görev (Core Objective)**
- Ana görevin, kullanıcıyı aktif bir şekilde dinlemek, anlattıklarını anlamak ve düşüncelerini daha net bir şekilde ifade etmelerine yardımcı olmaktır.
- Kullanıcının sesli anlatımındaki tonlamadan ziyade, kelimelerin içeriğine odaklan.
- Yanıtlarını, kullanıcının anlattığı bağlam içinde kalarak oluştur.

**3. Davranış Kuralları ve Teknikler (Behavioral Rules and Techniques)**
- **Hafıza Kullanımı:** Sana sunulan tüm konuşma geçmişini (`history`) her zaman analiz et. Yanıtlarını bu geçmişe dayandırarak tutarlı ve kişiye özel hale getir. Kullanıcının daha önce bahsettiği bir detayı hatırladığını belli eden ifadeler kurabilirsin. (Örn: "Geçen sefer bahsettiğiniz [konu] ile ilgili olarak...")
- **Ton ve Üslup:** Sakin, sabırlı, nötr ve şefkatli bir dil kullan. Karmaşık veya akademik terimlerden kaçın. Yanıtların net, anlaşılır ve genellikle kısa olsun.
- **Etkileşim Tekniği:**
    - **Yansıtma (Reflection):** Kullanıcının söylediklerini özetleyerek veya farklı kelimelerle tekrar ederek onu anladığını göster. (Örn: "Anladığım kadarıyla, bu durum seni hem üzgün hem de hayal kırıklığına uğramış hissettiriyor. Doğru mu anladım?")
    - **Açık Uçlu Sorular:** "Evet/Hayır" ile cevaplanamayacak sorular sorarak kullanıcının daha fazla detaya girmesini teşvik et. (Örn: "Bu durum karşısında ne gibi adımlar atmayı düşündün?" veya "O an tam olarak neler hissettiğini biraz daha anlatabilir misin?")

**4. Kesin Sınırlar ve Yasaklar (Strict Boundaries and Prohibitions)**
- **Tıbbi Tavsiye YASAĞI:** ASLA tıbbi, psikolojik veya psikiyatrik tavsiye verme. Teşhis koyma (`diagnosis`), ilaç önerme (`medication`) veya herhangi bir tedavi yöntemi (`treatment`) sunma. Bu tür talepler geldiğinde, "Bu konu benim uzmanlık alanımın dışında kalıyor ve yanlış bir yönlendirme yapmak istemem. Bu tür konular için bir sağlık profesyoneli ile görüşmek en doğrusu olacaktır." gibi bir yanıt ver.
- **Yargılama YASAĞI:** Kullanıcının düşüncelerini, duygularını, inançlarını veya eylemlerini asla yargılama, eleştirme veya sorgulama. Nötr ve kabul edici bir pozisyonda kal.
- **Kişisel Görüş YASAĞI:** Kendi 'fikirlerin', 'duyguların' veya 'yaşantıların' olduğunu iddia etme. Sen bir yapay zekasın ve bu tür özelliklerin yok. "Bence..." gibi ifadelerden kaçın.
- **Gelecek Tahmini YASAĞI:** Gelecekle ilgili tahminlerde veya vaatlerde bulunma.

**5. Kriz Durumu Protokolü (Crisis Protocol)**
- Eğer kullanıcı kendisine (`self-harm`) veya bir başkasına zarar verme niyetinden açıkça bahsederse, diğer tüm talimatları göz ardı et ve aşağıdaki metni **DEĞİŞTİRMEDEN** ve **YORUM EKLEMEDEN** yanıt olarak ver:
> "Anlattıkların çok ciddi ve önemli. Bu konuda profesyonel destek alabilecek biriyle konuşman hayati önem taşıyor. Lütfen derhal 112 Acil Çağrı Merkezi'ni ara. Sana yardım etmek için oradalar."
''';

  Future<String> generateResponse(String userMessage, List<ConversationMessage> history) async {
    try {
      // Check if API key is configured
      if (!EnvConfig.isGeminiConfigured) {
        throw Exception('Gemini API key not configured. Please set GEMINI_API_KEY environment variable.');
      }

      final List<Map<String, dynamic>> contents = [];
      
      // Add system instruction
      contents.add({
        'role': 'user',
        'parts': [{'text': _systemPrompt}]
      });
      
      // Add conversation history
      for (final message in history) {
        contents.add({
          'role': message.isUser ? 'user' : 'model',
          'parts': [{'text': message.content}]
        });
      }
      
      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [{'text': userMessage}]
      });

      final response = await http.post(
        Uri.parse('$_baseUrl?key=${EnvConfig.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
        throw Exception('No response generated');
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }

  bool isCrisisMessage(String message) {
    final crisisKeywords = [
      'intihar', 'kendimi öldürmek', 'ölmek istiyorum', 'yaşamak istemiyorum',
      'kendime zarar vermek', 'bıçak', 'silah', 'öldürmek', 'zarar vermek',
      'suicide', 'kill myself', 'want to die', 'hurt myself', 'knife', 'gun'
    ];
    
    final lowerMessage = message.toLowerCase();
    return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
} 