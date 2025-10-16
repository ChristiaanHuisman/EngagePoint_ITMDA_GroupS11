import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart'; 

class NotificationService {
  // Create an instance of Firebase Messaging
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  // Create an instance of our FirestoreService
  final FirestoreService _firestoreService = FirestoreService();

  // Function to initialize notifications and save the token
  Future<void> initAndSaveToken() async {
    // Request permission from the user (for iOS and modern Android)
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final String? fcmToken = await _firebaseMessaging.getToken();

    // Save the token to Firestore if it exists
    if (fcmToken != null) {
      await _firestoreService.saveUserToken(fcmToken);
    }
    
    // For debugging purposes
    debugPrint('FCM Token: $fcmToken');
  }
}