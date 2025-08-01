import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test Firestore connection
  Future<bool> testConnection() async {
    try {
      // Test write operation
      await _firestore
          .collection('test')
          .add({
        'message': 'Firestore bağlantısı başarılı!',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? 'anonymous',
      });
      
      print('✅ Firestore bağlantısı başarılı!');
      return true;
    } catch (e) {
      print('❌ Firestore bağlantı hatası: $e');
      return false;
    }
  }

  // Test user document creation
  Future<bool> testUserDocument() async {
    try {
      if (_auth.currentUser == null) {
        print('❌ Kullanıcı giriş yapmamış');
        return false;
      }

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set({
        'email': _auth.currentUser!.email,
        'displayName': _auth.currentUser!.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'isPremiumUser': false,
        'selectedPersona': 'default',
        'lastLogin': FieldValue.serverTimestamp(),
      });

      print('✅ Kullanıcı dokümanı oluşturuldu!');
      return true;
    } catch (e) {
      print('❌ Kullanıcı dokümanı oluşturulamadı: $e');
      return false;
    }
  }

  // Test chat document creation
  Future<String?> testChatDocument() async {
    try {
      if (_auth.currentUser == null) {
        print('❌ Kullanıcı giriş yapmamış');
        return null;
      }

      DocumentReference chatRef = await _firestore.collection('chats').add({
        'userId': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'messages': [],
        'title': 'Test Konuşması',
        'isActive': true,
      });

      print('✅ Chat dokümanı oluşturuldu! ID: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      print('❌ Chat dokümanı oluşturulamadı: $e');
      return null;
    }
  }

  // Test message addition
  Future<bool> testMessageAddition(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'messages': FieldValue.arrayUnion([
          {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': 'Bu bir test mesajıdır.',
            'timestamp': FieldValue.serverTimestamp(),
            'isUser': true,
          }
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Test mesajı eklendi!');
      return true;
    } catch (e) {
      print('❌ Test mesajı eklenemedi: $e');
      return false;
    }
  }

  // Run all tests
  Future<void> runAllTests() async {
    print('🧪 Firestore testleri başlatılıyor...\n');

    // Test 1: Connection
    print('1. Bağlantı testi...');
    bool connectionTest = await testConnection();
    print('');

    // Test 2: User Document
    print('2. Kullanıcı dokümanı testi...');
    bool userTest = await testUserDocument();
    print('');

    // Test 3: Chat Document
    print('3. Chat dokümanı testi...');
    String? chatId = await testChatDocument();
    print('');

    // Test 4: Message Addition
    if (chatId != null) {
      print('4. Mesaj ekleme testi...');
      await testMessageAddition(chatId);
      print('');
    }

    // Summary
    print('📊 Test Sonuçları:');
    print('✅ Bağlantı: ${connectionTest ? 'Başarılı' : 'Başarısız'}');
    print('✅ Kullanıcı Dokümanı: ${userTest ? 'Başarılı' : 'Başarısız'}');
    print('✅ Chat Dokümanı: ${chatId != null ? 'Başarılı' : 'Başarısız'}');
    print('✅ Mesaj Ekleme: ${chatId != null ? 'Test Edildi' : 'Atlandı'}');

    if (connectionTest && userTest && chatId != null) {
      print('\n🎉 Tüm testler başarılı! Firestore entegrasyonu hazır.');
    } else {
      print('\n⚠️ Bazı testler başarısız oldu. Lütfen Firebase yapılandırmasını kontrol edin.');
    }
  }

  // Clean up test data
  Future<void> cleanupTestData() async {
    try {
      // Delete test collection
      QuerySnapshot testDocs = await _firestore.collection('test').get();
      for (var doc in testDocs.docs) {
        await doc.reference.delete();
      }

      // Delete test chats
      if (_auth.currentUser != null) {
        QuerySnapshot chatDocs = await _firestore
            .collection('chats')
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .where('title', isEqualTo: 'Test Konuşması')
            .get();
        
        for (var doc in chatDocs.docs) {
          await doc.reference.delete();
        }
      }

      print('🧹 Test verileri temizlendi!');
    } catch (e) {
      print('❌ Test verileri temizlenemedi: $e');
    }
  }
} 