import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';
import '../pages/review_page.dart';
import '../pages/user_profile_page.dart';
import '../pages/edit_review_page.dart';

class ReviewCard extends StatefulWidget {
  final ReviewModel review;
  final bool showBusinessName;

  const ReviewCard({
    super.key,
    required this.review,
    this.showBusinessName = false,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final FirestoreService _firestoreService = FirestoreService();
  DocumentSnapshot? _customerProfile;
  DocumentSnapshot? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    try {
      final String customerId = widget.review.customerId;
      final String businessId = widget.review.businessId;

      final futures = <Future<DocumentSnapshot?>>[];
      futures.add(_firestoreService.getUserProfile(customerId));
      if (widget.showBusinessName) {
        futures.add(_firestoreService.getUserProfile(businessId));
      }

      final profiles = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _customerProfile = profiles.isNotEmpty ? profiles[0] : null;
          _businessProfile = profiles.length > 1 ? profiles[1] : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profiles for review card: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmation(BuildContext context, String businessId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Review?'),
          content: const Text('Are you sure you want to permanently delete your review?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _firestoreService.deleteReview(businessId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReplyDialog(BuildContext context, String reviewId) {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reply to Review'),
          content: TextField(
            controller: replyController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Your response',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Submit Reply'),
              onPressed: () {
                if (replyController.text.trim().isNotEmpty) {
                  _firestoreService.addResponseToReview(reviewId, replyController.text.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String customerName = 'Anonymous';
    String? customerPhotoUrl;
    if (_customerProfile != null && _customerProfile!.exists) {
      final customerData = _customerProfile!.data() as Map<String, dynamic>;
      customerName = customerData['name'] ?? 'Anonymous';
      customerPhotoUrl = customerData['photoUrl'];
    }

    String businessName = 'A Business';
    if (_businessProfile != null && _businessProfile!.exists) {
      final businessData = _businessProfile!.data() as Map<String, dynamic>;
      businessName = businessData['name'] ?? 'A Business';
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isReviewOwner = currentUserId != null && currentUserId == widget.review.customerId;
    final bool isBusinessOwner = currentUserId != null && currentUserId == widget.review.businessId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReviewPage(review: widget.review)),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar, name, stars
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!widget.showBusinessName && widget.review.customerId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserProfilePage(userId: widget.review.customerId)),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          customerPhotoUrl != null ? NetworkImage(customerPhotoUrl) : null,
                      child: customerPhotoUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          Text('Loading...', style: TextStyle(color: Colors.grey.shade500))
                        else if (widget.showBusinessName)
                          GestureDetector(
                            onTap: () {
                              if (widget.review.businessId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserProfilePage(userId: widget.review.businessId),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Review for: $businessName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // ✅ normal color
                                decoration: TextDecoration.none, // ✅ no underline
                              ),
                            ),
                          )
                        else
                          Text(
                            customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < widget.review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  if (isReviewOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditReviewPage(review: widget.review)),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _showDeleteConfirmation(context, widget.review.businessId),
                        ),
                      ],
                    ),
                ],
              ),

              const Divider(height: 24),

              Text(
                widget.review.comment,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StreamBuilder<bool>(
                    stream: _firestoreService.hasUserReactedToReview(widget.review.id),
                    builder: (context, snapshot) {
                      final hasReacted = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          hasReacted ? Icons.favorite : Icons.favorite_border,
                          color: hasReacted ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          _firestoreService.toggleReviewReaction(widget.review.id);
                        },
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _firestoreService.getReviewReactionCount(widget.review.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        count.toString(),
                        style: TextStyle(color: Colors.grey[600]),
                      );
                    },
                  ),
                ],
              ),

              if (isBusinessOwner && widget.review.response == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showReplyDialog(context, widget.review.id),
                    child: const Text('Reply'),
                  ),
                ),

              if (widget.review.response != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Response from the business:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.review.response!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
