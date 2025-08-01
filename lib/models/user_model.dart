import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final bool isPremiumUser;
  final String selectedPersona;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.isPremiumUser = false,
    this.selectedPersona = 'default',
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPremiumUser': isPremiumUser,
      'selectedPersona': selectedPersona,
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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      isPremiumUser: isPremiumUser ?? this.isPremiumUser,
      selectedPersona: selectedPersona ?? this.selectedPersona,
    );
  }
} 