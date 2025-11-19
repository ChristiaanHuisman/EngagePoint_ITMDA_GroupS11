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
      {required bool isBusiness,
      String? businessType,
      String? description,
      String? website}) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(name);

      await _createUserDocument(
        user,
        name: name,
        isBusiness: isBusiness,
        businessType: businessType,
        description: description,
        website: website,
      );
      await _notificationService.initAndSaveToken();
    }
    return user;
  }

  /// Signs out the current user from Firebase Auth and Google Sign-In (if applicable).
  Future<void> signOut() async {
    try {
      // FIX 1: Only sign out of Google if the user is actually signed in with Google.
      // This prevents the PlatformException.
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      // This catch is important in case the channel is disconnected
      // but 'isSignedIn' was still true.
      debugPrint("Error during Google sign out: $e");
    }
    // Always sign out of Firebase Auth
    await _auth.signOut();
  }

  /// Deletes the user's Auth account and their Firestore document.
  /// This function assumes the user has logged in recently.
  /// If it fails with 'requires-recent-login', the UI should call [reAuthenticateAndDelete].
  Future<void> deleteUserAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user is currently logged in.");
      }
      
      // --- FIX 2: REVERSED THE ORDER ---
      // 1. Delete Firestore data FIRST (while user is still logged in)
      // This prevents a 'permission-denied' error.
      await _firestore.collection('users').doc(user.uid).delete();

      // 2. Delete Auth user LAST
      await user.delete();
      
      // 3. Sign out (this will now call our new, safe function)
      await signOut();

    } on FirebaseAuthException catch (_) {
      // Re-throw the original error so the UI can read its 'code' (e.g., 'requires-recent-login')
      rethrow; 
    } catch (e) {
      throw Exception('An error occurred: ${e.toString()}');
    }
  }

  /// Prompts the user to re-enter their password, then securely deletes their account.
  /// This is the secure flow for handling "sensitive" actions.
  Future<void> reAuthenticateAndDelete(String password) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not found or email is null.");
      }

      // 1. Create a credential with the user's password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // 2. Re-authenticate the user to get a fresh token
      await user.reauthenticateWithCredential(credential);

      // 3. Re-authentication SUCCESS! Now we can safely delete.
      final String uid = user.uid;

      // --- FIX 2: REVERSED THE ORDER ---
      // 3a. Delete Firestore data FIRST
      await _firestore.collection('users').doc(uid).delete(); 
      
      // (Optional) Delete user's storage data if you have any
      
      // 3b. Delete Auth user LAST
      await user.delete(); 
      
      // 3c. Sign out (this will now call our new, safe function)
      await signOut();

    } on FirebaseAuthException catch (e) {
      // Handle "wrong-password" error during re-auth
      if (e.code == 'wrong-password') {
        throw Exception('Incorrect password. Please try again.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}