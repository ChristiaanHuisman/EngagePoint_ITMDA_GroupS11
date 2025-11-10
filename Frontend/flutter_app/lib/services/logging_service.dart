import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// service for handling all event logging within the app.
class LoggingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Logs a user action to the debug console for testing purposes.
  void logUserAction({required String action, Map<String, dynamic>? details}) {
    final String message = 'User Action: $action. Details: ${details ?? {}}';
    debugPrint(message);
  }

  // Logs an admin-specific action to the 'auditLogs' collection in Firestore.
  void logAdminAction(
      {required String action, required Map<String, dynamic> details}) {
    final String message = '[AUDIT] Admin Action: $action. Details: $details';
    debugPrint(message);

    final currentUser = _auth.currentUser;

    if (currentUser == null) return;

    _db.collection('auditLogs').add({
      'actorUserId': currentUser.uid,
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Logs an error to the debug console.
  void logError({required String error, StackTrace? stackTrace}) {
    final String message = '[ERROR] $error';
    debugPrint(message);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  // Logs a custom event to Firebase Analytics
  Future<void> logAnalyticsEvent(
      {required String eventName, Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      debugPrint("Logged analytics event: '$eventName'");
    } catch (e) {
      logError(error: "Failed to log analytics event: $e");
    }
  }
}
