# Dinleyen Zeka - Sesli Etkileşimli Kişisel Danışman Uygulaması

Bu proje, **Gemini 2.0 Flash** yapay zeka modelinin multimodal yeteneklerini temel alan, sesli etkileşimli bir kişisel danışman uygulamasının Minimum Uygulanabilir Ürün (MVP) sürümüdür.

## 🎯 Proje Amacı

Bu MVP'nin temel amacı, ses tabanlı yapay zeka etkileşiminin ve hafıza fonksiyonunun teknik fizibilitesini ve kullanıcı kabulünü test etmektir. Uygulama profesyonel bir terapi veya tıbbi danışmanlık hizmeti sunmamaktadır.

## ✨ Özellikler

- **Sesli Etkileşim**: Kullanıcının sesli anlatımlarını doğrudan işleme
- **Speech-to-Text**: Speech-to-Text ara katmanına olan ihtiacı ortadan kaldırma
- **Akıcı Diyalog**: Daha akıcı bir diyalog akışı sağlama
- **Hafıza Fonksiyonu**: Geçmiş konuşmaları referans alarak bağlama duyarlı yanıtlar
- **Text-to-Speech**: AI yanıtlarını sese dönüştürme
- **Firebase Entegrasyonu**: Güvenli veri saklama ve senkronizasyon
- **Kriz Protokolü**: Acil durumlar için otomatik yönlendirme

## 🛠️ Teknolojiler

- **Flutter**: Cross-platform mobil uygulama geliştirme
- **Gemini 2.0 Flash**: Google'ın en gelişmiş AI modeli
- **Firebase**: Authentication ve Firestore veritabanı
- **Speech-to-Text**: Gerçek zamanlı ses tanıma
- **Text-to-Speech**: AI yanıtlarını sese dönüştürme
- **Provider**: State management

## 📱 Kurulum

### Gereksinimler

- Flutter SDK (3.8.0+)
- Android Studio / VS Code
- Android SDK (API 21+)
- iOS Simulator (macOS için)

### Adımlar

1. **Projeyi klonlayın**
   ```bash
   git clone <repository-url>
   cd mobilapp_pysc
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Firebase yapılandırması**
   - Firebase Console'da yeni proje oluşturun
   - Android uygulaması ekleyin
   - `google-services.json` dosyasını `android/app/` klasörüne yerleştirin
   - Firestore veritabanını etkinleştirin

4. **Gemini API Key**
   - `lib/services/gemini_service.dart` dosyasında `_apiKey` değişkenini güncelleyin

5. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

## 🔧 Yapılandırma

### Firebase Kurulumu

1. Firebase Console'a gidin
2. Yeni proje oluşturun
3. Android uygulaması ekleyin
4. `google-services.json` dosyasını indirin
5. Firestore veritabanını etkinleştirin

### Gemini API Key

1. Google AI Studio'ya gidin
2. API key oluşturun
3. `lib/services/gemini_service.dart` dosyasında güncelleyin

## 📁 Proje Yapısı

```
lib/
├── models/
│   └── conversation.dart          # Konuşma modeli
├── services/
│   ├── firebase_service.dart      # Firebase işlemleri
│   ├── gemini_service.dart        # Gemini AI entegrasyonu
│   ├── speech_service.dart        # Speech-to-Text
│   └── tts_service.dart          # Text-to-Speech
├── providers/
│   └── chat_provider.dart         # State management
├── screens/
│   └── chat_screen.dart          # Ana ekran
├── widgets/
│   ├── message_bubble.dart        # Mesaj balonu
│   └── voice_button.dart          # Ses butonu
└── main.dart                     # Uygulama girişi
```

## 🎨 UI/UX Özellikleri

- **Modern Tasarım**: Koyu tema ile göz dostu arayüz
- **Animasyonlar**: Ses durumları için görsel geri bildirim
- **Responsive**: Farklı ekran boyutlarına uyum
- **Erişilebilirlik**: Voice-over desteği

## 🔒 Güvenlik

- **Anonim Kimlik Doğrulama**: Kullanıcı gizliliği
- **Güvenli Veri Saklama**: Firebase Firestore
- **Kriz Protokolü**: Acil durumlar için otomatik müdahale

## ⚠️ Önemli Notlar

- Bu uygulama profesyonel bir terapi veya tıbbi danışmanlık hizmeti sunmamaktadır
- Ciddi konular için mutlaka bir sağlık profesyoneli ile görüşünüz
- Kriz durumlarında 112 Acil Çağrı Merkezi'ni arayınız

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📞 İletişim

Proje hakkında sorularınız için issue açabilirsiniz.
