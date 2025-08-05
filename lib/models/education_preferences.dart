class EducationPreferences {
  static const Map<String, String> educationLevels = {
    'primary_school': 'İlkokul',
    'middle_school': 'Ortaokul',
    'high_school': 'Lise',
    'university': 'Üniversite',
    'graduate': 'Yüksek Lisans',
    'phd': 'Doktora',
    'professional': 'Profesyonel',
    'self_study': 'Kendi Kendine Öğrenme',
  };

  static const Map<String, String> learningStyles = {
    'visual': 'Görsel Öğrenme',
    'auditory': 'İşitsel Öğrenme',
    'kinesthetic': 'Kinestetik Öğrenme',
    'reading': 'Okuma/Yazma',
    'mixed': 'Karma Öğrenme',
  };

  static const Map<String, String> studyEnvironments = {
    'home': 'Ev',
    'library': 'Kütüphane',
    'cafe': 'Kafe',
    'office': 'Ofis',
    'outdoor': 'Açık Alan',
    'classroom': 'Sınıf',
  };

  static const Map<String, String> voiceStyles = {
    'professional': 'Profesyonel',
    'friendly': 'Arkadaşça',
    'casual': 'Günlük',
    'energetic': 'Enerjik',
  };

  static const List<String> commonSubjects = [
    'Matematik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Tarih',
    'Coğrafya',
    'Türkçe',
    'İngilizce',
    'Felsefe',
    'Psikoloji',
    'Sosyoloji',
    'Ekonomi',
    'Bilgisayar Bilimi',
    'Mühendislik',
    'Tıp',
    'Hukuk',
    'İşletme',
    'Sanat',
    'Müzik',
    'Spor',
    'Dil Öğrenimi',
    'Programlama',
    'Veri Bilimi',
    'Yapay Zeka',
    'Robotik',
    'Astronomi',
    'Jeoloji',
    'Çevre Bilimi',
    'Siyaset Bilimi',
    'Uluslararası İlişkiler',
  ];

  static const List<String> commonLearningGoals = [
    'Sınavlara Hazırlanma',
    'Kariyer Gelişimi',
    'Kişisel Gelişim',
    'Hobi Öğrenme',
    'Yeni Dil Öğrenme',
    'Teknoloji Öğrenme',
    'Sanat ve Kültür',
    'Spor ve Sağlık',
    'Finansal Okuryazarlık',
    'Liderlik Becerileri',
    'İletişim Becerileri',
    'Problem Çözme',
    'Kritik Düşünme',
    'Yaratıcılık',
    'Takım Çalışması',
    'Zaman Yönetimi',
    'Stres Yönetimi',
    'Dijital Okuryazarlık',
  ];

  static const List<String> commonWeakAreas = [
    'Matematik',
    'Fen Bilimleri',
    'Sosyal Bilimler',
    'Dil Becerileri',
    'Yazma',
    'Okuma',
    'Konuşma',
    'Dinleme',
    'Problem Çözme',
    'Analitik Düşünme',
    'Yaratıcı Düşünme',
    'Hafıza',
    'Odaklanma',
    'Zaman Yönetimi',
    'Organizasyon',
    'Motivasyon',
    'Özgüven',
    'Sosyal Beceriler',
  ];

  static const List<String> commonStrongAreas = [
    'Matematik',
    'Fen Bilimleri',
    'Sosyal Bilimler',
    'Dil Becerileri',
    'Yazma',
    'Okuma',
    'Konuşma',
    'Dinleme',
    'Problem Çözme',
    'Analitik Düşünme',
    'Yaratıcı Düşünme',
    'Hafıza',
    'Odaklanma',
    'Zaman Yönetimi',
    'Organizasyon',
    'Motivasyon',
    'Özgüven',
    'Sosyal Beceriler',
  ];

  static String getEducationLevelDisplay(String key) {
    return educationLevels[key] ?? key;
  }

  static String getLearningStyleDisplay(String key) {
    return learningStyles[key] ?? key;
  }

  static String getStudyEnvironmentDisplay(String key) {
    return studyEnvironments[key] ?? key;
  }

  static String getVoiceStyleDisplay(String key) {
    return voiceStyles[key] ?? key;
  }
} 