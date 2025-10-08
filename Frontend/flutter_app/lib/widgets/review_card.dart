import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

// A widget that displays a single review in a styled format.
class ReviewCard extends StatefulWidget {
  final DocumentSnapshot review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final FirestoreService _firestoreService = FirestoreService();
  DocumentSnapshot? _customerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerProfile();
  }

  Future<void> _fetchCustomerProfile() async {
    try {
      final reviewData = widget.review.data() as Map<String, dynamic>;
      final String? customerId = reviewData['customerId'];
      
      if (customerId != null) {
        final profile = await _firestoreService.getUserProfile(customerId);
        if (mounted) {
          setState(() {
            _customerProfile = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching customer profile for review: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.review.data() as Map<String, dynamic>;
    final String comment = data['comment'] ?? 'No comment provided.';
    // Get the rating and ensure it's a double between 1 and 5.
    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    
    String customerName = 'Anonymous';
    if (_customerProfile != null && _customerProfile!.exists) {
      final customerData = _customerProfile!.data() as Map<String, dynamic>;
      customerName = customerData['name'] ?? 'Anonymous';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display the customer's name
                _isLoading
                    ? Text('Loading...', style: TextStyle(color: Colors.grey.shade500))
                    : Text(
                        customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                // Display the star rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(comment),
          ],
        ),
      ),
    );
  }
}
