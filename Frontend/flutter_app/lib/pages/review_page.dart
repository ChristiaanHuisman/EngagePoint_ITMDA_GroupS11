import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'user_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewPage extends StatefulWidget {
  final ReviewModel review;

  const ReviewPage({super.key, required this.review});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _customerProfile;
  UserModel? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
  final String reviewId = widget.review.id;
  debugPrint("ReviewPage: fetching profiles for reviewId=$reviewId");

  try {
    final String customerId = widget.review.customerId;
    final String businessId = widget.review.businessId;

    UserModel? customer;
    UserModel? business;

    if (customerId.isNotEmpty) {
      try {
        customer = await _firestoreService.getUserProfile(customerId);
      } catch (e, st) {
        debugPrint(
            "ReviewPage: error fetching customer profile for review=$reviewId customerId=$customerId -> $e\n$st");
      }
    } else {
      debugPrint("ReviewPage: empty customerId for review=$reviewId");
    }

    if (businessId.isNotEmpty) {
      try {
        business = await _firestoreService.getUserProfile(businessId);
      } catch (e, st) {
        debugPrint(
            "ReviewPage: error fetching business profile for review=$reviewId businessId=$businessId -> $e\n$st");
      }
    } else {
      debugPrint("ReviewPage: empty businessId for review=$reviewId");
    }

    if (mounted) {
      setState(() {
        _customerProfile = customer;
        _businessProfile = business;
        _isLoading = false;
      });
    }
  } catch (e, st) {
    debugPrint(
        "ReviewPage: unexpected error fetching profiles for review=${widget.review.id} -> $e\n$st");
    if (mounted) setState(() => _isLoading = false);
  }
}

  

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final String customerName = _customerProfile?.name ?? 'Anonymous';
    final String businessName = _businessProfile?.name ?? 'The Business';
    final String? customerPhotoUrl = _customerProfile?.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              GestureDetector(
                onTap: () {
                  final String targetUserId = widget.review.customerId;
                  if (targetUserId.isNotEmpty) {
                    if (targetUserId == currentUserId) {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfilePage(userId: targetUserId),
                        ),
                      );
                    }
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: customerPhotoUrl != null
                          ? NetworkImage(customerPhotoUrl)
                          : null,
                      child: customerPhotoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Reviewed $businessName'),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < widget.review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            const Divider(height: 32),
            Text(
              widget.review.comment,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(height: 1.6, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                StreamBuilder<bool>(
                  stream: _firestoreService
                      .hasUserReactedToReview(widget.review.id),
                  builder: (context, snapshot) {
                    final hasReacted = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        hasReacted ? Icons.favorite : Icons.favorite_border,
                        color: hasReacted ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        _firestoreService
                            .toggleReviewReaction(widget.review.id);
                      },
                    );
                  },
                ),
                StreamBuilder<int>(
                  stream: _firestoreService
                      .getReviewReactionCount(widget.review.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '$count likes',
                      style: TextStyle(
                          color: Colors.grey[600], fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),
            if (widget.review.response != null &&
                widget.review.response!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response from $businessName:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.review.response!),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
