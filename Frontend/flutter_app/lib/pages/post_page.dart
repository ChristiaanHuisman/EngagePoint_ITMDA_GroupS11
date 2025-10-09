import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'user_profile_page.dart';

class PostPage extends StatefulWidget {
  final QueryDocumentSnapshot post;

  const PostPage({super.key, required this.post});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
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
      debugPrint("Error fetching business profile on post page: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.post.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? 'No Content';
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(timestamp.toDate());
    final String? imageUrl = data['imageUrl'];

    String businessName = '...';
    String? businessPhotoUrl;
    String businessId = '';
    
    if (_businessProfile != null && _businessProfile!.exists) {
      final businessData = _businessProfile!.data() as Map<String, dynamic>;
      businessName = businessData['name'] ?? 'Unnamed Business';
      businessPhotoUrl = businessData['photoUrl'];
      businessId = _businessProfile!.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 50));
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_businessProfile != null)
                    GestureDetector(
                      onTap: () {
                        if (businessId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfilePage(userId: businessId),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: businessPhotoUrl != null ? NetworkImage(businessPhotoUrl) : null,
                                radius: 22,
                                child: businessPhotoUrl == null ? const Icon(Icons.store, size: 22) : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    businessName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Posted on $formattedDate',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  const Divider(height: 24),

                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 16),
                  ),

                 
                  // like button and counter
                  const SizedBox(height: 24),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        StreamBuilder<bool>(
                          stream: _firestoreService.hasUserReacted(widget.post.id),
                          builder: (context, snapshot) {
                            final hasReacted = snapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                hasReacted ? Icons.favorite : Icons.favorite_border,
                                color: hasReacted ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                _firestoreService.togglePostReaction(widget.post.id);
                              },
                            );
                          },
                        ),
                        StreamBuilder<int>(
                          stream: _firestoreService.getPostReactionCount(widget.post.id),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

