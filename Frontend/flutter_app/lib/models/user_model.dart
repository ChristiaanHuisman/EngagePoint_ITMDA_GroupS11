import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role;
  final String status;
  final String? businessType;
  final String? description;
  final int points;
  final int spinsAvailable;
  final List<String> notificationTags;
  final Timestamp createdAt;
  final String? timezone;
  final Timestamp? verifiedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.status,
    this.businessType,
    this.description,
    this.points = 0,
    this.spinsAvailable = 0,
    this.notificationTags = const [],
    required this.createdAt,
    this.timezone,
    this.verifiedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? 'No Email',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'customer',
      status: data['status'] ?? 'verified',
      businessType: data['businessType'],
      description: data['description'],
      points: data['points'] ?? 0,
      spinsAvailable: data['spinsAvailable'] ?? 0,
      notificationTags: List<String>.from(data['notificationTags'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      timezone: data['timezone'],
      verifiedAt: data['verifiedAt'],
    );
  }
  
  // Helper getter to make role checks cleaner in the UI
  bool get isBusiness => role == 'business';

  // Helper to convert the model to a map for writing to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'searchName': name.toLowerCase(),
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'status': status,
      'businessType': businessType,
      'description': description,
      'points': points,
      'spinsAvailable': spinsAvailable,
      'notificationTags': notificationTags,
      'createdAt': createdAt,
      'timezone': timezone,
      'verifiedAt': verifiedAt,
    };
  }
}