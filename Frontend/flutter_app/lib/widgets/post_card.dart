import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../pages/business_profile_page.dart';
import '../pages/post_page.dart'; 

/// A widget that displays a single post in a card format.
class PostCard extends StatefulWidget {
  final QueryDocumentSnapshot post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirestoreService _firestoreService = FirestoreService();
  DocumentSnapshot? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBusinessProfile();
  }

  Future<void> _fetchBusinessProfile() async {
    try {
      final postData = widget.post.data() as Map<String, dynamic>;
      final String? businessId = postData['businessId'];
      
      if (businessId != null) {
        final profile = await _firestoreService.getUserProfile(businessId);
        if (mounted) {
          setState(() {
            _businessProfile = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching business profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.post.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? 'No Content';
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('MMM dd, yyyy').format(timestamp.toDate());

    String businessName = 'Anonymous Business';
    String? businessPhotoUrl;
    String businessId = '';
    if (_businessProfile != null && _businessProfile!.exists) {
      final businessData = _businessProfile!.data() as Map<String, dynamic>;
      businessName = businessData['name'] ?? 'Unnamed Business';
      businessPhotoUrl = businessData['photoUrl'];
      businessId = _businessProfile!.id;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostPage(post: widget.post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const LinearProgressIndicator(),
              if (!_isLoading && _businessProfile != null)
                GestureDetector(
                  onTap: () {
                    if (businessId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusinessProfilePage(businessId: businessId),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: businessPhotoUrl != null
                              ? NetworkImage(businessPhotoUrl)
                              : null,
                          radius: 20,
                          child: businessPhotoUrl == null ? const Icon(Icons.store, size: 20) : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

