import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// A dedicated service for handling all event logging within the app.
/// This centralizes logic for analytics, audit trails, and error reporting.
class LoggingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // An instance of the Firebase Analytics service.
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs a generic user action to the debug console for development purposes.
  /// This can be used for simple, temporary logging to trace user behavior.
  void logUserAction({required String action, Map<String, dynamic>? details}) {
    final String message = 'User Action: $action. Details: ${details ?? {}}';
    debugPrint(message);
  }

  /// Logs an admin-specific action to the 'auditLogs' collection in Firestore.
  /// This creates a permanent, secure record of important admin activities.
  void logAdminAction({required String action, required Map<String, dynamic> details}) {
    final String message = '[AUDIT] Admin Action: $action. Details: $details';
    debugPrint(message);

    final currentUser = _auth.currentUser;
    // An admin must be logged in to perform an audited action.
    if (currentUser == null) return;

    _db.collection('auditLogs').add({
      'actorUserId': currentUser.uid,
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Logs an error to the debug console.
  /// Provides more context than a simple print statement.
  void logError({required String error, StackTrace? stackTrace}) {
    final String message = '[ERROR] $error';
    debugPrint(message);
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
    // In a production app, this is where you would integrate with a crash
    // reporting service like Sentry or Firebase Crashlytics.
  }

  /// Logs a custom event to Firebase Analytics.
  /// This is used to track specific user interactions for data analysis in your C# microservice.
  Future<void> logAnalyticsEvent({required String eventName, Map<String, Object>? parameters}) async {
    try {
      // Use the FirebaseAnalytics instance to log the event.
      // `eventName` should be a descriptive, snake_case string (e.g., 'post_reaction_added').
      // `parameters` is an optional map providing more context about the event.
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

