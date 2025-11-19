import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/notification_preferences_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import '../services/logging_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final LoggingService _loggingService = LoggingService();

  Future<void> _createUserDocument(User user,
      {String? name,
      bool isBusiness = false,
      String? businessType,
      String? description,
      String? website}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    //  get raw result
    final dynamic tzRaw = await FlutterTimezone.getLocalTimezone();
    debugPrint('DEBUG → getLocalTimezone raw: $tzRaw (${tzRaw.runtimeType})');

    //  normalize to IANA timezone string
    String normalizeTimezone(dynamic tz) {
      if (tz == null) return 'UTC';

      if (tz is String) {
        final s = tz.trim();
        if (s.contains('/')) return s;
      }

      final str = tz.toString();
      final regex = RegExp(r'TimezoneInfo\(\s*([A-Za-z_\/\-]+)');
      final m = regex.firstMatch(str);
      if (m != null && m.groupCount >= 1) {
        return m.group(1)!;
      }

      final tokenMatch =
          RegExp(r'([A-Za-z_\/\-]+\/[A-Za-z_\/\-]+)').firstMatch(str);
      if (tokenMatch != null) return tokenMatch.group(1)!;

      return 'UTC';
    }

    final String localTimezone = normalizeTimezone(tzRaw);
    debugPrint('DEBUG → Normalized timezone to save: $localTimezone');

    // compute offset
    final now = DateTime.now();
    final String timezoneOffset = now.timeZoneOffset.isNegative
        ? '-${now.timeZoneOffset.inHours.abs().toString().padLeft(2, '0')}:${(now.timeZoneOffset.inMinutes.abs() % 60).toString().padLeft(2, '0')}'
        : '+${now.timeZoneOffset.inHours.toString().padLeft(2, '0')}:${(now.timeZoneOffset.inMinutes % 60).toString().padLeft(2, '0')}';
    debugPrint('DEBUG → timezoneOffset: $timezoneOffset');
    debugPrint('DEBUG → Computed offset = $timezoneOffset');

    if (!docSnapshot.exists) {
      final newUser = UserModel(
        uid: user.uid,
        name: name ?? user.displayName ?? 'New User',
        email: user.email ?? 'No Email',
        photoUrl: user.photoURL,
        role: isBusiness ? 'business' : 'customer',
        status: isBusiness ? 'pending' : 'verified',
        createdAt: Timestamp.now(),
        nextFreeSpinAt: DateTime(2000),
        timezone: localTimezone,
        timezoneOffset: timezoneOffset,
        notificationPreferences: NotificationPreferences(),
        emailVerified: user.emailVerified,
        verificationStatus: 'notStarted',
        businessType: businessType,
        description: description,
        website: website,
      );

      final userData = newUser.toMap();
      userData['createdAt'] = FieldValue.serverTimestamp();

      debugPrint('DEBUG → Writing user data: $userData');
      await userRef.set(userData);
    } else {
      debugPrint(
          'DEBUG → Updating timezone fields: $localTimezone | $timezoneOffset');
      await userRef.set({
        'timezone': localTimezone,
        'timezoneOffset': timezoneOffset,
      }, SetOptions(merge: true));
    }
  }

  FirebaseAuth get auth => _auth;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await _createUserDocument(result.user!);
        await _notificationService.initAndSaveToken();
      }
      _loggingService.logAnalyticsEvent(
        eventName: 'user_login',
        parameters: {
          'method': 'email',
          'user_id': result.user?.uid ?? 'unknown'
        },
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
        await _notificationService.initAndSaveToken();
      }
      _loggingService.logAnalyticsEvent(
        eventName: 'user_login',
        parameters: {
          'method': 'google',
          'user_id': result.user?.uid ?? 'unknown'
        },
      );
      return result.user;
    } catch (e) {
      debugPrint("Google login error: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String name,
      {required bool isBusiness}) async {
    try {
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      
      if (user != null) {
        debugPrint("Step 1 Success: Auth User Created (${user.uid})");
        
        await user.updateDisplayName(name);
        
        try {
          await _createUserDocument(user, name: name, isBusiness: isBusiness);
          debugPrint("Step 2 Success: Firestore Document Created");
        } catch (e) {
          debugPrint("Step 2 FAILED: Firestore Write Error: $e");
          rethrow; 
        }
        
        try {
          await _notificationService.initAndSaveToken();
          debugPrint("Step 3 Success: Notifications Setup");
        } catch (e) {
          debugPrint("Step 3 WARNING: Notification Error (Ignored): $e");
        }
        
        return user;
      }
      
      return null;
      
    } catch (e) {
      debugPrint("CRITICAL SIGN UP ERROR: $e");
      return null;
    }
  }
  /// Signs out the current user from Firebase Auth and Google Sign-In 
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint("Error during Google sign out: $e");
    }
    // Always sign out of Firebase Auth
    await _auth.signOut();
  }

  Future<void> deleteUserAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user is currently logged in.");
      }

      await _firestore.collection('users').doc(user.uid).delete();

      await user.delete();
      
      await signOut();

    } on FirebaseAuthException catch (_) {
      rethrow; 
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  Future<void> reAuthenticateAndDelete(String password) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not found or email is null.");
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final String uid = user.uid;

      await _firestore.collection('users').doc(uid).delete(); 
      
      await user.delete(); 
      
      await signOut();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}