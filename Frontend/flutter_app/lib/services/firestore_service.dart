import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/review_model.dart';
import 'package:flutter_app/models/post_model.dart';
import 'package:flutter_app/services/logging_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:jose/jose.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';

// Top-level function to get the token
Future<String> getCloudRunIdToken(String cloudRunUrl) async {
  // 1️⃣ Load the service account JSON
  final jsonString = await rootBundle.loadString('assets/service_account.json');
  final account = jsonDecode(jsonString);

  final clientEmail = account['client_email'];
  final privateKey = account['private_key'];

  // 2️⃣ Create JWT header and claims
  final claimSet = JsonWebTokenClaims.fromJson({
    'iss': clientEmail,
    'sub': clientEmail,
    'aud': 'https://oauth2.googleapis.com/token',
    'target_audience': cloudRunUrl,
    'iat': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
  });

  final builder = JsonWebSignatureBuilder()
    ..jsonContent = claimSet.toJson()
    ..addRecipient(
      JsonWebKey.fromPem(privateKey, keyId: account['private_key_id']),
      algorithm: 'RS256',
    );

  final jws = builder.build();
  final jwt = jws.toCompactSerialization();

  // 3️⃣ Exchange JWT for an ID token
  final response = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': jwt,
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to get ID token: ${response.body}');
  }

  final data = jsonDecode(response.body);
  return data['id_token'];
}



class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LoggingService _loggingService = LoggingService();

  // Creates a new post document in the 'posts' collection.
  Future<void> createPost({
    required String title,
    required String content,
    String? imageUrl,
    double? imageAspectRatio,
    String? tag,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("No user is logged in to create a post.");
    }

    // Use UserModel for safer role checking
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception("User profile not found. Cannot verify role.");
    }

    final userModel = UserModel.fromFirestore(userDoc);
    if (!userModel.isBusiness) {
      throw Exception(
          "Permission denied. Only business users can create posts.");
    }

    await _db.collection('posts').add({
      'businessId': user.uid,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'imageAspectRatio': imageAspectRatio,
      'tag': tag,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'published',
    });
  }

  Stream<List<PostModel>> getAllPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<PostModel>> getPostsForBusiness(String businessId) {
    return _db
        .collection('posts')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<PostModel>> getFollowedPosts(List<String> businessIds) {
    if (businessIds.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('posts')
        .where('businessId', whereIn: businessIds)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  // Fetches a user's profile data from the 'users' collection by their UID.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // Follows a business by creating a document in the 'follows' collection.
  Future<void> followBusiness(String businessId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db.collection('follows').doc('${currentUser.uid}_$businessId').set({
      'customerId': currentUser.uid,
      'businessId': businessId,
      'followedAt': FieldValue.serverTimestamp(),
    });

    _loggingService.logAnalyticsEvent(
      //analytics logging
      eventName: 'business_follow',
      parameters: {
        'customer_id': currentUser.uid,
        'business_id': businessId,
      },
    );
  }

  // Unfollows a business by deleting the corresponding document.
  Future<void> unfollowBusiness(String businessId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db
        .collection('follows')
        .doc('${currentUser.uid}_$businessId')
        .delete();
  }

  // Checks if the current user is following a specific business.
  Stream<bool> isFollowing(String businessId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);
    return _db
        .collection('follows')
        .doc('${currentUser.uid}_$businessId')
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Gets the real-time follower count for a business.
  Stream<int> getFollowerCount(String businessId) {
    return _db
        .collection('follows')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Returns a stream containing a list of business IDs the current user follows.
  Stream<List<String>> getFollowedBusinesses() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);
    return _db
        .collection('follows')
        .where('customerId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['businessId'] as String)
          .toList();
    });
  }

  // Searches for businesses by name.
  Stream<List<UserModel>> searchBusinesses(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }
    final lowercaseQuery = query.toLowerCase();
    return _db
        .collection('users')
        .where('role', isEqualTo: 'business')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // REVIEW METHODS USING PYTHON MiCROSERVICE  

  // Adds a new review or updates an existing one for a business using Python API.
  Future<void> addOrUpdateReview({
    required String businessId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("You must be logged in to leave a review.");
    }

    final url = Uri.parse('https://review-sentiment-service-570976278139.africa-south1.run.app/reviews');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await getCloudRunIdToken('https://review-sentiment-service-570976278139.africa-south1.run.app')}'},
      body: jsonEncode({
        'businessId': businessId,
        'customerId': currentUser.uid,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to submit review: ${response.body}');
    }
  }

  // Gets all reviews for a business using Python API (for non-stream use).
  Future<List<Map<String, dynamic>>> getReviewsForBusinessApi(String businessId) async {
    final url = Uri.parse('https://review-sentiment-service-570976278139.africa-south1.run.app/reviews/$businessId');
    final response = await http.get(url,headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await getCloudRunIdToken('https://review-sentiment-service-570976278139.africa-south1.run.app')}'},);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load reviews: ${response.body}');
    }
  }

  // Deletes a review using Python API.
  Future<void> deleteReview(String businessId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final url = Uri.parse('https://review-sentiment-service-570976278139.africa-south1.run.app/reviews');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await getCloudRunIdToken('https://review-sentiment-service-570976278139.africa-south1.run.app')}'},
      body: jsonEncode({
        'businessId': businessId,
        'customerId': currentUser.uid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete review: ${response.body}');
    }
  }

  // END API REVIEW METHODS

  // Returns a stream of reviews for a specific business (from Firestore).
  Stream<List<ReviewModel>> getReviewsForBusiness(String businessId) {
    return _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<ReviewModel> reviews = [];
      for (var doc in snapshot.docs) {
        try {
          reviews.add(ReviewModel.fromFirestore(doc));
        } catch (e) {
          debugPrint("Error parsing review ${doc.id}: $e");
        }
      }
      return reviews;
    });
  }

  // Gets the real-time average rating and review count for a business.
  Stream<Map<String, double>> getReviewStats(String businessId) {
    return _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return {'count': 0.0, 'average': 0.0};
      }
      double totalRating = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
      }
      double averageRating = totalRating / snapshot.docs.length;
      return {
        'count': snapshot.docs.length.toDouble(),
        'average': averageRating,
      };
    });
  }

  // Returns a stream of all business users with a 'pending' status.
  Stream<List<UserModel>> getPendingBusinesses() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'business')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // Updates a user's status field in their document.
  Future<void> updateUserStatus(String uid, String status) async {
    if (status == 'verified' || status == 'rejected') {
      await _db.collection('users').doc(uid).update({'status': status});
    }
  }

  // Deletes a post from the 'posts' collection.
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  // Adds a response from a business to a review document.
  Future<void> addResponseToReview(String reviewId, String response) async {
    await _db.collection('reviews').doc(reviewId).update({
      'response': response,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // Updates a user's profile document with new data.
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    if (data.containsKey('name')) {
      data['searchName'] = (data['name'] as String).toLowerCase();
    }
    await _db.collection('users').doc(uid).update(data);
  }

  // Returns a stream of ReviewModels.
  // Returns a stream of reviews written by a specific customer.
  Stream<List<ReviewModel>> getReviewsForCustomer(String customerId) {
    return _db
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  // Updates an existing post document with new data.
  Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
    String? imageUrl,
    double? imageAspectRatio,
    String? tag,
  }) async {
    await _db.collection('posts').doc(postId).update({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'imageAspectRatio': imageAspectRatio,
      'tag': tag,
    });
  }

  // Toggles a user's reaction (like) on a post.
  Future<void> togglePostReaction(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final reactionRef = _db
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(currentUser.uid);
    final reactionDoc = await reactionRef.get();
    if (reactionDoc.exists) {
      await reactionRef.delete();
    } else {
      await reactionRef.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // Checks if the current user has reacted to a specific post.
  Stream<bool> hasUserReacted(String postId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);
    return _db
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Gets the real-time count of reactions for a post.
  Stream<int> getPostReactionCount(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Toggles a user's like on a review.
  Future<void> toggleReviewReaction(String reviewId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final reactionRef = _db
        .collection('reviews')
        .doc(reviewId)
        .collection('reactions')
        .doc(currentUser.uid);
    final reactionDoc = await reactionRef.get();
    if (reactionDoc.exists) {
      await reactionRef.delete();
    } else {
      await reactionRef.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  // Checks if the current user has liked a specific review.
  Stream<bool> hasUserReactedToReview(String reviewId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);
    return _db
        .collection('reviews')
        .doc(reviewId)
        .collection('reactions')
        .doc(currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Gets the real-time count of likes for a review.
  Stream<int> getReviewReactionCount(String reviewId) {
    return _db
        .collection('reviews')
        .doc(reviewId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Saves or updates the user's FCM token in a 'devices' subcollection.
  Future<void> saveUserToken(String token) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final deviceRef = _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('devices')
        .doc(token);
    await deviceRef.set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  // Gets the total number of likes across all posts for a business.
  Future<int> getTotalLikesForBusiness(String businessId) async {
    final postsQuery = await _db
        .collection('posts')
        .where('businessId', isEqualTo: businessId)
        .get();
    int totalLikes = 0;
    for (final postDoc in postsQuery.docs) {
      final reactionsQuery =
          await postDoc.reference.collection('reactions').get();
      totalLikes += reactionsQuery.size;
    }
    return totalLikes;
  }

  // Gets the total number of reviews for a business.
  Future<int> getTotalReviewsForBusiness(String businessId) async {
    final reviewsQuery = await _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .get();
    return reviewsQuery.size;
  }

Future<Map<String, int>> getReviewSentimentStats(String businessId) async {
  final url = Uri.parse('https://review-sentiment-service-570976278139.africa-south1.run.app/reviews/analytics/$businessId');
  final response = await http.get(url,headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await getCloudRunIdToken('https://review-sentiment-service-570976278139.africa-south1.run.app')}'},);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'positive': data['positive'] ?? 0,
      'negative': data['negative'] ?? 0,
      'neutral': data['neutral'] ?? 0,
    };
  } else {
    throw Exception('Failed to fetch sentiment stats: ${response.body}');
  }
}

  Future<void> addLocation(
      {required String name, required String address}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('locations')
        .add({
      'name': name,
      'address': address,
    });
  }

  // Gets a real-time stream of locations for a specific business.
  Stream<List<LocationModel>> getLocations(String businessId) {
    return _db
        .collection('users')
        .doc(businessId)
        .collection('locations')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromFirestore(doc))
            .toList());
  }

  // Updates an existing location document for the current business.
  Future<void> updateLocation({
    required String locationId,
    required String name,
    required String address,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('locations')
        .doc(locationId)
        .update({
      'name': name,
      'address': address,
    });
  }

  // Deletes a location document for the current business.
  Future<void> deleteLocation({required String locationId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('locations')
        .doc(locationId)
        .delete();
  }

  Stream<UserModel?> getUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Provides a stream of a user's profile for any given user ID.
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Updates the current user's points by a given amount.
  Future<void> updateUserPoints(int pointsToAdd) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final userRef = _db.collection('users').doc(currentUser.uid);
    // Use a transaction to safely update the points
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        return;
      }
      final currentPoints =
          (snapshot.data() as Map<String, dynamic>)['points'] ?? 0;
      final newPoints = currentPoints + pointsToAdd;
      transaction.update(userRef, {'points': newPoints});
    });
  }

  // update user notification preferences

  Future<void> updateUserPreference(String key, dynamic value) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _db.collection('users').doc(currentUser.uid).update({
      'notificationPreferences.$key': value,
    });
  }

  // Fetches a single post by its document ID
  Future<PostModel?> getPostById(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    return doc.exists ? PostModel.fromFirestore(doc) : null;
  }

  // Fetches a single review by its document ID
  Future<ReviewModel?> getReviewById(String reviewId) async {
    final doc = await _db.collection('reviews').doc(reviewId).get();
    return doc.exists ? ReviewModel.fromFirestore(doc) : null;
  }

  // Updates a single field within the notificationPreferences map.
  Future<void> updateNotificationPreference(String key, dynamic value) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Use dot notation to update a field in a nested map
    await _db.collection('users').doc(currentUser.uid).update({
      'notificationPreferences.$key': value,
    });
  }

// Overwrites the list of subscribed tags.
  Future<void> updateSubscribedTags(List<String> tags) async {
    await updateNotificationPreference('subscribedTags', tags);
  }

  Future<void> updateUserPrivacy(bool isPrivate) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _db.collection('users').doc(currentUser.uid).update({
      'isPrivate': isPrivate,
    });
  }
}
