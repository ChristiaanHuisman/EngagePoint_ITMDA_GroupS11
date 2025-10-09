import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'user_profile_page.dart';

class ReviewPage extends StatefulWidget {
  final DocumentSnapshot review;

  const ReviewPage({super.key, required this.review});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
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
      final reviewData = widget.review.data() as Map<String, dynamic>;
      final String? customerId = reviewData['customerId'];
      final String? businessId = reviewData['businessId'];

      if (customerId != null && businessId != null) {
        // Fetch both profiles concurrently for better performance
        final profiles = await Future.wait([
          _firestoreService.getUserProfile(customerId),
          _firestoreService.getUserProfile(businessId),
        ]);
        if (mounted) {
          setState(() {
            _customerProfile = profiles[0];
            _businessProfile = profiles[1];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching profiles for review page: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.review.data() as Map<String, dynamic>;
    final String comment = data['comment'] ?? 'No comment provided.';
    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final String? response = data['response'];
    final String customerId = data['customerId'] ?? '';
    final String businessId = data['businessId'] ?? '';

    String customerName = 'Anonymous';
    String businessName = 'The Business';
    String? customerPhotoUrl;

    if (_customerProfile != null && _customerProfile!.exists) {
      final customerData = _customerProfile!.data() as Map<String, dynamic>;
      customerName = customerData['name'] ?? 'Anonymous';
      customerPhotoUrl = customerData['photoUrl'];
    }
    if (_businessProfile != null && _businessProfile!.exists) {
      businessName = (_businessProfile!.data() as Map<String, dynamic>)['name'] ?? 'The Business';
    }

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
                  if (customerId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserProfilePage(userId: customerId)),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: customerPhotoUrl != null ? NetworkImage(customerPhotoUrl) : null,
                      child: customerPhotoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),
            const Divider(height: 32),
            Text(
              comment,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 16),
            ),
            
            const SizedBox(height: 24),
          
            // This Row contains the simplified like button and counter.
            Row(
              children: [
                StreamBuilder<bool>(
                  stream: _firestoreService.hasUserReactedToReview(widget.review.id),
                  builder: (context, snapshot) {
                    final hasReacted = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        hasReacted ? Icons.favorite : Icons.favorite_border,
                        color: hasReacted ? Colors.red : Colors.grey,
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
                      '$count likes',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ],
            ),

            if (response != null && response.isNotEmpty) ...[
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
                    Text(response),
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

