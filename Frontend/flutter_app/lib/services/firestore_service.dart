import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/review_model.dart';
import '../services/logging_service.dart';
import '../models/post_model.dart';

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

    final userDoc = await _db.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception("User profile not found. Cannot verify role.");
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String role = userData['role'] ?? 'customer';

    if (role != 'business') {
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
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _db.collection('users').doc(uid).get();
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

    _loggingService.logAnalyticsEvent( //analytics logging
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
  Stream<QuerySnapshot<Object?>> searchBusinesses(String query) {
    if (query.isEmpty) {
      return _db.collection('__nonexistent__').snapshots();
    }

    final lowercaseQuery = query.toLowerCase();

    return _db
        .collection('users')
        .where('role', isEqualTo: 'business')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots();
  }

  // Returns a stream of ReviewModels.
  // Returns a stream of reviews for a specific business.
  Stream<List<ReviewModel>> getReviewsForBusiness(String businessId) {
    return _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
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

  // Accepts a single ReviewModel object.
  // Adds a new review or updates an existing one for a business.
  Future<void> addOrUpdateReview({required ReviewModel review}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("You must be logged in to leave a review.");
    }

    final reviewRef = _db
        .collection('reviews')
        .doc('${currentUser.uid}_${review.businessId}');

    final reviewData = review.toMap();
    reviewData['createdAt'] = FieldValue.serverTimestamp();

    await reviewRef.set(reviewData, SetOptions(merge: true));
  }

  // Returns a stream of all business users with a 'pending' status.
  Stream<QuerySnapshot<Object?>> getPendingBusinesses() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'business')
        .where('status', isEqualTo: 'pending')
        .snapshots();
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

  // Deletes a review from the 'reviews' collection.
  Future<void> deleteReview(String businessId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db
        .collection('reviews')
        .doc('${currentUser.uid}_$businessId')
        .delete();
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
  /// Returns a stream of reviews written by a specific customer.
  Stream<List<ReviewModel>> getReviewsForCustomer(String customerId) {
    return _db
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList());
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

  /// Gets the real-time count of reactions for a post.
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

  /// Checks if the current user has liked a specific review.
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

  /// Gets the real-time count of likes for a review.
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
  
  // New methods for the business dashboard

  /// Gets the total number of likes across all posts for a business.
  Future<int> getTotalLikesForBusiness(String businessId) async {
    final postsQuery = await _db
        .collection('posts')
        .where('businessId', isEqualTo: businessId)
        .get();

    int totalLikes = 0;

    // This is inefficient for large numbers of posts. For a production app,
    // you would use a Cloud Function to update a counter. But for this project, it's fine.
    for (final postDoc in postsQuery.docs) {
      final reactionsQuery =
          await postDoc.reference.collection('reactions').get();
      totalLikes += reactionsQuery.size;
    }

    return totalLikes;
  }

  /// Gets the total number of reviews for a business.
  Future<int> getTotalReviewsForBusiness(String businessId) async {
    final reviewsQuery = await _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .get();
    return reviewsQuery.size;
  }

  Future<Map<String, int>> getReviewSentimentStats(String businessId) async {
    final querySnapshot = await _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return {'positive': 0, 'negative': 0, 'neutral': 0};
    }

    int positiveCount = 0;
    int negativeCount = 0;
    int neutralCount = 0;

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      // This assumes your Python microservice saves a field named 'sentiment'
      // with values like 'positive', 'negative', or 'neutral'.
      final String? sentiment = data['sentiment'];

      switch (sentiment) {
        case 'positive':
          positiveCount++;
          break;
        case 'negative':
          negativeCount++;
          break;
        case 'neutral':
          neutralCount++;
          break;
      }
    }

    return {
      'positive': positiveCount,
      'negative': negativeCount,
      'neutral': neutralCount,
    };
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

  /// Gets a real-time stream of locations for a specific business.
  Stream<QuerySnapshot> getLocations(String businessId) {
    return _db
        .collection('users')
        .doc(businessId)
        .collection('locations')
        .snapshots();
  }

  /// Updates an existing location document for the current business.
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

  /// Deletes a location document for the current business.
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

  Stream<DocumentSnapshot> getUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();
    return _db.collection('users').doc(currentUser.uid).snapshots();
  }

  /// Updates the current user's points by a given amount.
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

  // New method to update user notification preferences
  Future<void> updateNotificationPreferences(List<String> tags) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser.uid).update({
      'notificationTags': tags,
    });
  }
}
