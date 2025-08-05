import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final bool isPremiumUser;
  final String selectedPersona;
  
  // Eğitim tercihleri
  final List<String> studySubjects;
  final String educationLevel;
  final String learningStyle;
  final List<String> learningGoals;
  final String preferredLanguage;
  final int studyTimePerDay; // dakika cinsinden
  final List<String> weakAreas;
  final List<String> strongAreas;
  final String studyEnvironment;
  final bool enableNotifications;
  final String preferredVoiceStyle;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.isPremiumUser = false,
    this.selectedPersona = 'default',
    this.studySubjects = const [],
    this.educationLevel = 'high_school',
    this.learningStyle = 'visual',
    this.learningGoals = const [],
    this.preferredLanguage = 'tr-TR',
    this.studyTimePerDay = 60,
    this.weakAreas = const [],
    this.strongAreas = const [],
    this.studyEnvironment = 'home',
    this.enableNotifications = true,
    this.preferredVoiceStyle = 'professional',
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPremiumUser': isPremiumUser,
      'selectedPersona': selectedPersona,
      'studySubjects': studySubjects,
      'educationLevel': educationLevel,
      'learningStyle': learningStyle,
      'learningGoals': learningGoals,
      'preferredLanguage': preferredLanguage,
      'studyTimePerDay': studyTimePerDay,
      'weakAreas': weakAreas,
      'strongAreas': strongAreas,
      'studyEnvironment': studyEnvironment,
      'enableNotifications': enableNotifications,
      'preferredVoiceStyle': preferredVoiceStyle,
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPremiumUser: data['isPremiumUser'] ?? false,
      selectedPersona: data['selectedPersona'] ?? 'default',
      studySubjects: List<String>.from(data['studySubjects'] ?? []),
      educationLevel: data['educationLevel'] ?? 'high_school',
      learningStyle: data['learningStyle'] ?? 'visual',
      learningGoals: List<String>.from(data['learningGoals'] ?? []),
      preferredLanguage: data['preferredLanguage'] ?? 'tr-TR',
      studyTimePerDay: data['studyTimePerDay'] ?? 60,
      weakAreas: List<String>.from(data['weakAreas'] ?? []),
      strongAreas: List<String>.from(data['strongAreas'] ?? []),
      studyEnvironment: data['studyEnvironment'] ?? 'home',
      enableNotifications: data['enableNotifications'] ?? true,
      preferredVoiceStyle: data['preferredVoiceStyle'] ?? 'professional',
    );
  }

  // Create UserModel from Firebase Auth User
  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      createdAt: DateTime.now(),
      isPremiumUser: false,
      selectedPersona: 'default',
    );
  }

  // Copy with method for updating specific fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? isPremiumUser,
    String? selectedPersona,
    List<String>? studySubjects,
    String? educationLevel,
    String? learningStyle,
    List<String>? learningGoals,
    String? preferredLanguage,
    int? studyTimePerDay,
    List<String>? weakAreas,
    List<String>? strongAreas,
    String? studyEnvironment,
    bool? enableNotifications,
    String? preferredVoiceStyle,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      selectedPersona: selectedPersona ?? this.selectedPersona,
      studySubjects: studySubjects ?? this.studySubjects,
      educationLevel: educationLevel ?? this.educationLevel,
      learningStyle: learningStyle ?? this.learningStyle,
      learningGoals: learningGoals ?? this.learningGoals,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      studyTimePerDay: studyTimePerDay ?? this.studyTimePerDay,
      weakAreas: weakAreas ?? this.weakAreas,
      strongAreas: strongAreas ?? this.strongAreas,
      studyEnvironment: studyEnvironment ?? this.studyEnvironment,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      preferredVoiceStyle: preferredVoiceStyle ?? this.preferredVoiceStyle,
    );
  }
} 