import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Firebase Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Check if user is logged in
  static bool get isLoggedIn => auth.currentUser != null;

  // Get current user
  static User? get currentUser => auth.currentUser;
}