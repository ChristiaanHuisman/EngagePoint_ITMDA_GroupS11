import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_preferences_model.dart';

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
  final DateTime nextFreeSpinAt;
  final List<String> notificationTags;
  final Timestamp createdAt;
  final String? timezone;
  final String? timezoneOffset;
  final Timestamp? verifiedAt;
  final NotificationPreferences notificationPreferences;
  final bool isPrivate;
  final bool emailVerified;
  final String verificationStatus;
  final String? website;
  final Timestamp? verificationRequestedAt;


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
    required this.nextFreeSpinAt,
    this.notificationTags = const [],
    required this.createdAt,
    this.timezone,
    this.timezoneOffset,
    this.verifiedAt,
    required this.notificationPreferences,
    this.isPrivate = false,
    required this.emailVerified,
    required this.verificationStatus,
    this.website,
    this.verificationRequestedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Timestamp? spinTs = data['nextFreeSpinAt'];
    // If null, set to past so they can spin now
    DateTime spinDate = spinTs?.toDate() ?? DateTime(2000);

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
      nextFreeSpinAt: spinDate,
      notificationTags: List<String>.from(data['notificationTags'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      timezone: data['timezone'],
      timezoneOffset: data['timezoneOffset'],
      verifiedAt: data['verifiedAt'],
      notificationPreferences: NotificationPreferences.fromMap(data['notificationPreferences']),
      isPrivate: data['isPrivate'] ?? false,
      emailVerified: data['emailVerified'] ?? false,
      verificationStatus: data['verificationStatus'] ?? 'notStarted',
      website: data['website'],
      verificationRequestedAt: data['verificationRequestedAt'],
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
      'nextFreeSpinAt': Timestamp.fromDate(nextFreeSpinAt),
      'notificationTags': notificationTags,
      'createdAt': createdAt,
      'timezone': timezone,
      'timezoneOffset': timezoneOffset, 
      'verifiedAt': verifiedAt,
      'isPrivate': isPrivate,
      'emailVerified': emailVerified,
      'verificationStatus': verificationStatus,
      'website': website,
      'verificationRequestedAt': verificationRequestedAt,
   

      "notificationPreferences": {
        "onNewPost": true,
        "onReviewResponse": true,
        "onNewReview": true,
        "onPostLike": false,
        "onNewFollower": true,
        "subscribedTags": [],
        "quietTimeEnabled": false,
        "quietTimeStart": "22:00",
        "quietTimeEnd": "08:00"
      }
    };
  }
}