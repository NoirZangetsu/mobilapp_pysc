# Kurulum Kılavuzu

Bu dosya, Dinleyen Zeka uygulamasının Firebase ve Gemini API yapılandırmasını açıklar.

## 🚀 Hızlı Başlangıç

### 1. Environment Variables Kurulumu

Otomatik kurulum script'ini çalıştırın:

```bash
./scripts/setup_env.sh
```

Bu script size gerekli API key'leri soracak ve `.env` dosyası oluşturacak.

### 2. Environment Variables'ları Yükleme

```bash
source .env
```

### 3. Uygulamayı Çalıştırma

```bash
flutter run
```

## 🔥 Firebase Kurulumu

### 1. Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Proje ekle" butonuna tıklayın
3. Proje adını girin (örn: "dinleyen-zeka")
4. Google Analytics'i etkinleştirin (opsiyonel)
5. "Proje oluştur" butonuna tıklayın

### 2. Android Uygulaması Ekleme

1. Firebase Console'da projenizi seçin
2. Android simgesine tıklayın
3. Android paket adını girin: `com.example.mobilapp_pysc`
4. Uygulama takma adını girin (opsiyonel)
5. "Uygulama kaydet" butonuna tıklayın
6. `google-services.json` dosyasını indirin
7. İndirilen dosyayı `android/app/` klasörüne kopyalayın

### 3. Firestore Veritabanı Kurulumu

1. Firebase Console'da "Firestore Database" seçin
2. "Veritabanı oluştur" butonuna tıklayın
3. Test modunda başlatın (güvenlik kurallarını daha sonra yapılandırabilirsiniz)
4. Bölge seçin (örn: europe-west3)

### 4. Firebase Environment Variables

Firebase Console'dan aldığınız bilgileri environment variables olarak ayarlayın:

```bash
export FIREBASE_API_KEY="your_firebase_api_key"
export FIREBASE_APP_ID="your_firebase_app_id"
export FIREBASE_PROJECT_ID="your_project_id"
export FIREBASE_SENDER_ID="your_sender_id"
export FIREBASE_STORAGE_BUCKET="your_project_id.appspot.com"
```

## 🤖 Gemini API Kurulumu

### 1. Google AI Studio'ya Erişim

1. [Google AI Studio](https://aistudio.google.com/) adresine gidin
2. Google hesabınızla giriş yapın
3. "Get API key" butonuna tıklayın
4. Yeni bir API key oluşturun

### 2. Gemini API Key'i Ayarlama

```bash
export GEMINI_API_KEY="your_gemini_api_key_here"
```

## 🔧 Manuel Environment Variables Kurulumu

Eğer otomatik script kullanmak istemiyorsanız, manuel olarak environment variables ayarlayabilirsiniz:

### Terminal'de Ayarlama

```bash
# Gemini API
export GEMINI_API_KEY="your_gemini_api_key"

# Firebase Configuration
export FIREBASE_API_KEY="your_firebase_api_key"
export FIREBASE_APP_ID="your_firebase_app_id"
export FIREBASE_PROJECT_ID="your_project_id"
export FIREBASE_SENDER_ID="your_sender_id"
export FIREBASE_STORAGE_BUCKET="your_project_id.appspot.com"
```

### .env Dosyası Oluşturma

Proje kök dizininde `.env` dosyası oluşturun:

```bash
# .env dosyası
export GEMINI_API_KEY="your_gemini_api_key"
export FIREBASE_API_KEY="your_firebase_api_key"
export FIREBASE_APP_ID="your_firebase_app_id"
export FIREBASE_PROJECT_ID="your_project_id"
export FIREBASE_SENDER_ID="your_sender_id"
export FIREBASE_STORAGE_BUCKET="your_project_id.appspot.com"
```

Sonra yükleyin:

```bash
source .env
```

## 🔧 Uygulama İzinleri

### Android İzinleri

`android/app/src/main/AndroidManifest.xml` dosyasına aşağıdaki izinleri ekleyin:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS İzinleri

`ios/Runner/Info.plist` dosyasına aşağıdaki izinleri ekleyin:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Bu uygulama sesli konuşma için mikrofon erişimi gerektirir.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Bu uygulama konuşma tanıma için erişim gerektirir.</string>
```

## 🚀 Uygulamayı Çalıştırma

### 1. Bağımlılıkları Yükleme

```bash
flutter pub get
```

### 2. Environment Variables'ları Yükleme

```bash
source .env
```

### 3. Uygulamayı Test Etme

```bash
flutter run
```

### 4. Production Build

```bash
flutter build apk --release
```

## 🔒 Güvenlik Notları

1. **API Key'leri Güvenli Tutun**: API key'lerinizi asla public repository'lere commit etmeyin
2. **Environment Variables**: Production ortamında environment variable'ları kullanın
3. **Firebase Rules**: Firestore güvenlik kurallarını yapılandırın
4. **Rate Limiting**: API kullanım limitlerini kontrol edin
5. **.env Dosyası**: .env dosyasının .gitignore'da olduğundan emin olun

## 🐛 Sorun Giderme

### Environment Variables Kontrolü

Environment variables'ların doğru ayarlandığını kontrol etmek için:

```bash
echo $GEMINI_API_KEY
echo $FIREBASE_API_KEY
echo $FIREBASE_PROJECT_ID
```

### Firebase Bağlantı Sorunu

- Environment variables'ların doğru ayarlandığından emin olun
- Firebase Console'da proje ayarlarını kontrol edin
- Internet bağlantınızı kontrol edin

### Gemini API Sorunu

- GEMINI_API_KEY environment variable'ının ayarlandığından emin olun
- API kullanım limitlerini kontrol edin
- Network bağlantınızı kontrol edin

### Ses Tanıma Sorunu

- Mikrofon izinlerini kontrol edin
- Cihazın mikrofonunun çalıştığından emin olun
- Türkçe dil paketinin yüklü olduğundan emin olun

## 📞 Destek

Sorun yaşarsanız:
1. Flutter doctor çıktısını kontrol edin: `flutter doctor`
2. Log'ları inceleyin
3. GitHub issues bölümünde sorun bildirin 