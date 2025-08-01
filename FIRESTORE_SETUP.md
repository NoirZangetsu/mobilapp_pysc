# Firestore Kurulum Rehberi

## 🔥 1. Firebase Console'da Firestore Veritabanı Oluşturma

### Adım 1: Firebase Console'a Giriş
1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. Projenizi seçin (veya yeni proje oluşturun)

### Adım 2: Firestore Database Oluşturma
1. Sol menüden "Firestore Database" seçin
2. "Veritabanı oluştur" butonuna tıklayın
3. Güvenlik modunu seçin:
   - **Test modunda başlat** (geliştirme için)
   - **Üretim modunda başlat** (production için)
4. Bölge seçin (örn: `europe-west3` - Avrupa)
5. "Tamam" butonuna tıklayın

### Adım 3: Güvenlik Kurallarını Ayarlama
1. Firestore Database > Rules sekmesine gidin
2. Aşağıdaki kuralları yapıştırın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar sadece kendi verilerine erişebilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chat mesajları için kurallar
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Kullanıcı profilleri
    match /userProfiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. "Yayınla" butonuna tıklayın

## 📱 2. Flutter Uygulamasında Firestore Entegrasyonu

### Adım 1: Bağımlılıkları Kontrol Edin
`pubspec.yaml` dosyasında şu bağımlılıkların olduğundan emin olun:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
```

### Adım 2: Firebase Yapılandırma Dosyalarını Kontrol Edin

#### Android için:
1. `android/app/google-services.json` dosyasının mevcut olduğundan emin olun
2. `android/app/build.gradle` dosyasında Google Services plugin'inin eklendiğini kontrol edin:

```gradle
// android/app/build.gradle
apply plugin: 'com.google.gms.google-services'
```

#### iOS için:
1. `ios/Runner/GoogleService-Info.plist` dosyasının mevcut olduğundan emin olun

### Adım 3: Firestore Servisini Test Edin

Aşağıdaki test kodunu kullanarak Firestore bağlantısını test edebilirsiniz:

```dart
// Test için geçici kod
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> testFirestoreConnection() async {
  try {
    // Test koleksiyonu oluştur
    await FirebaseFirestore.instance
        .collection('test')
        .add({
      'message': 'Firestore bağlantısı başarılı!',
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    print('✅ Firestore bağlantısı başarılı!');
  } catch (e) {
    print('❌ Firestore bağlantı hatası: $e');
  }
}
```

## 🗄️ 3. Veri Modeli ve Koleksiyon Yapısı

### Kullanıcı Koleksiyonu (`users`)
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "displayName": "Kullanıcı Adı",
  "createdAt": "2024-01-01T00:00:00Z",
  "isPremiumUser": false,
  "selectedPersona": "default"
}
```

### Chat Mesajları Koleksiyonu (`chats`)
```json
{
  "chatId": "chat123",
  "userId": "user123",
  "messages": [
    {
      "id": "msg1",
      "content": "Merhaba, nasılsın?",
      "timestamp": "2024-01-01T00:00:00Z",
      "isUser": true
    },
    {
      "id": "msg2", 
      "content": "İyiyim, teşekkürler!",
      "timestamp": "2024-01-01T00:01:00Z",
      "isUser": false
    }
  ],
  "createdAt": "2024-01-01T00:00:00Z",
  "lastUpdated": "2024-01-01T00:01:00Z"
}
```

## 🔧 4. Firestore Servis Sınıfı

Mevcut `AuthService` sınıfınızda Firestore entegrasyonu zaten mevcut. İşte örnek kullanım:

```dart
// Kullanıcı verisi oluşturma
await _firestore
    .collection('users')
    .doc(user.uid)
    .set(userModel.toMap());

// Kullanıcı verisi okuma
DocumentSnapshot doc = await _firestore
    .collection('users')
    .doc(uid)
    .get();

// Kullanıcı verisi güncelleme
await _firestore
    .collection('users')
    .doc(uid)
    .update({
  'isPremiumUser': true,
  'selectedPersona': 'therapist'
});
```

## 🚀 5. Test Etme

### Adım 1: Uygulamayı Çalıştırın
```bash
flutter run
```

### Adım 2: Kayıt Olun
1. Uygulamada yeni bir hesap oluşturun
2. Firebase Console > Firestore Database > Data sekmesine gidin
3. `users` koleksiyonunda yeni kullanıcının oluşturulduğunu kontrol edin

### Adım 3: Chat Mesajlarını Test Edin
1. Uygulamada bir konuşma başlatın
2. Firestore'da `chats` koleksiyonunda mesajların kaydedildiğini kontrol edin

## 🔒 6. Güvenlik Kontrol Listesi

- [ ] Firestore güvenlik kuralları yayınlandı
- [ ] Kullanıcı kimlik doğrulaması aktif
- [ ] Veri şifreleme ayarları kontrol edildi
- [ ] Backup stratejisi planlandı
- [ ] Rate limiting ayarları yapıldı

## 🐛 7. Sorun Giderme

### Yaygın Hatalar:

1. **"Permission denied" hatası:**
   - Güvenlik kurallarını kontrol edin
   - Kullanıcının authenticate olduğundan emin olun

2. **"Network error" hatası:**
   - İnternet bağlantısını kontrol edin
   - Firebase proje ayarlarını kontrol edin

3. **"Invalid document" hatası:**
   - Veri modelini kontrol edin
   - Timestamp formatını kontrol edin

## 📞 8. Destek

Sorun yaşarsanız:
1. Firebase Console loglarını kontrol edin
2. Flutter debug loglarını inceleyin
3. Firestore güvenlik kurallarını test edin
4. Firebase proje ayarlarını kontrol edin 