import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createUserDocument(User user, {String? name, bool isBusiness = false}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      String role = isBusiness ? 'business' : 'customer';
      String status = isBusiness ? 'pending' : 'verified';
      String displayName = name ?? user.displayName ?? 'New User';

      await userRef.set({
        'name': displayName,
        'searchName': displayName.toLowerCase(), // A lowercase version of the name is saved for case-insensitive searching.
        'email': user.email,
        'role': role,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL,
      });
    }
  }

  FirebaseAuth get auth => _auth;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint("Email login error: $e");
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        await _createUserDocument(user, isBusiness: false);
      }
      return user;
    } catch (e) {
      debugPrint("Google login error: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String name, {required bool isBusiness}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await _createUserDocument(user, name: name, isBusiness: isBusiness);
      }
      return user;
    } catch (e) {
      debugPrint("Sign up error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}

