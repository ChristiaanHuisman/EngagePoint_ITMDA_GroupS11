import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Creates a new post document in the 'posts' collection.
  Future<void> createPost({
    required String title,
    required String content,
    String? imageUrl,
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
      throw Exception("Permission denied. Only business users can create posts.");
    }

    await _db.collection('posts').add({
      'businessId': user.uid,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'published',
    });
  }

  // Fetches a user's profile data from the 'users' collection by their UID.
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // Returns a stream of posts created by a specific business.
  Stream<QuerySnapshot<Object?>> getPostsForBusiness(String businessId) {
    return _db
        .collection('posts')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots();
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
  }

  // Unfollows a business by deleting the corresponding document.
  Future<void> unfollowBusiness(String businessId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _db.collection('follows').doc('${currentUser.uid}_$businessId').delete();
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
          return snapshot.docs.map((doc) => doc.data()['businessId'] as String).toList();
        });
  }

  // Returns a stream of posts from a specific list of business IDs.
  Stream<QuerySnapshot<Object?>> getFollowedPosts(List<String> businessIds) {
    if (businessIds.isEmpty) {
        return _db.collection('__nonexistent__').snapshots();
    }
    return _db
        .collection('posts')
        .where('businessId', whereIn: businessIds)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  // Returns a stream of all posts for the Discover feed.
  Stream<QuerySnapshot<Object?>> getAllPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots();
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

  // Returns a stream of reviews for a specific business.
  Stream<QuerySnapshot<Object?>> getReviewsForBusiness(String businessId) {
    return _db
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots();
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
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] as num?)?.toDouble() ?? 0.0;
      }

      double averageRating = totalRating / snapshot.docs.length;
      return {
        'count': snapshot.docs.length.toDouble(),
        'average': averageRating,
      };
    });
  }
  
  // Adds a new review or updates an existing one for a business.
  Future<void> addOrUpdateReview({
    required String businessId,
    required double rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("You must be logged in to leave a review.");
    }

    final reviewRef = _db.collection('reviews').doc('${currentUser.uid}_$businessId');

    await reviewRef.set({
      'businessId': businessId,
      'customerId': currentUser.uid,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    await _db.collection('reviews').doc('${currentUser.uid}_$businessId').delete();
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

  /// Returns a stream of reviews written by a specific customer.
  Stream<QuerySnapshot<Object?>> getReviewsForCustomer(String customerId) {
    return _db
        .collection('reviews')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Updates an existing post document with new data.
  Future<void> updatePost({
    required String postId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    await _db.collection('posts').doc(postId).update({
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
    });
  }

  // Toggles a user's reaction (like) on a post.
  Future<void> togglePostReaction(String postId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final reactionRef = _db.collection('posts').doc(postId).collection('reactions').doc(currentUser.uid);
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
    return _db.collection('posts').doc(postId).collection('reactions').doc(currentUser.uid).snapshots().map((snapshot) => snapshot.exists);
  }

  /// Gets the real-time count of reactions for a post.
  Stream<int> getPostReactionCount(String postId) {
    return _db.collection('posts').doc(postId).collection('reactions').snapshots().map((snapshot) => snapshot.docs.length);
  }

  
  // The following methods have been simplified to handle a single 'like' reaction for reviews.

  // Toggles a user's like on a review.
  Future<void> toggleReviewReaction(String reviewId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final reactionRef = _db.collection('reviews').doc(reviewId).collection('reactions').doc(currentUser.uid);
    final reactionDoc = await reactionRef.get();

    if (reactionDoc.exists) {
      // If the user has already liked, remove their like.
      await reactionRef.delete();
    } else {
      // If the user has not liked, add their like.
      await reactionRef.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  /// Checks if the current user has liked a specific review.
  Stream<bool> hasUserReactedToReview(String reviewId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);

    return _db.collection('reviews').doc(reviewId).collection('reactions').doc(currentUser.uid).snapshots().map((snapshot) => snapshot.exists);
  }

  /// Gets the real-time count of likes for a review.
  Stream<int> getReviewReactionCount(String reviewId) {
    return _db.collection('reviews').doc(reviewId).collection('reactions').snapshots().map((snapshot) => snapshot.docs.length);
  }
  
}

