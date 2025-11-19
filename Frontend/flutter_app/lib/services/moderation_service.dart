import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ModerationException implements Exception {
  final String message;
  ModerationException(this.message);
  @override
  String toString() => 'ModerationException: $message';
}

class ModerationResult {
  final bool approved;
  final String? reason;
  final Map<String, dynamic>? raw;
  final int statusCode;

  ModerationResult({
    required this.approved,
    this.reason,
    this.raw,
    required this.statusCode,
  });

  factory ModerationResult.fromResponse(int statusCode, Map<String, dynamic> body) {
    final approved = body['approved'] == true || body['approved'] == 'true';
    final reason = body['reason']?.toString();
    return ModerationResult(approved: approved, reason: reason, raw: body, statusCode: statusCode);
  }
}

class ModerationService {
  // Cloud Run URL 
  final String baseUrl = 'https://post-moderation-service-570976278139.africa-south1.run.app';

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    try {
      // Get cached token 
      final token = await user.getIdToken();

      if (token == null || token.isEmpty) {
        throw ModerationException('Failed to retrieve authentication token');
      }

      return token;
    } on FirebaseAuthException catch (e) {
      // Handle known auth errors
      throw ModerationException('Firebase Auth error: ${e.code}');
    } catch (e) {
      // Catch any other unexpected errors
      throw ModerationException('Unexpected error retrieving token');
    }
  }



  Future<ModerationResult> moderateText(String content) async {
    final token = await _getIdToken();
    if (token == null) throw ModerationException('User not signed in');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseUrl/moderate-post');
    try {
      final resp = await http
          .post(uri, headers: headers, body: jsonEncode({'content': content}))
          .timeout(const Duration(seconds: 15));

      return _handleResp(resp);
    } catch (e) {
      throw ModerationException('Text moderation request failed: $e');
    }
  }

  Future<ModerationResult> moderateImage(String imageUrl) async {
    final token = await _getIdToken();
    if (token == null) throw ModerationException('User not signed in');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseUrl/moderate-image');
    try {
      final resp = await http
          .post(uri, headers: headers, body: jsonEncode({'image_url': imageUrl}))
          .timeout(const Duration(seconds: 20));

      return _handleResp(resp);
    } catch (e) {
      throw ModerationException('Image moderation request failed: $e');
    }
  }

  ModerationResult _handleResp(http.Response resp) {
    final status = resp.statusCode;
    if (status >= 200 && status < 300) {
      try {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        return ModerationResult.fromResponse(status, decoded);
      } catch (e) {
        // returned non-JSON or unexpected format
        throw ModerationException('Invalid moderation response format: $e — raw: ${resp.body}');
      }
    } else if (status == 401 || status == 403) {
      throw ModerationException('Unauthorized (status $status). Token may be invalid.');
    } else {
      // try to parse error body for message
      try {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final err = decoded['error'] ?? decoded['message'] ?? resp.body;
        throw ModerationException('Moderation failed ($status): $err');
      } catch (_) {
        throw ModerationException('Moderation failed with status $status and body: ${resp.body}');
      }
    }
  }
}
