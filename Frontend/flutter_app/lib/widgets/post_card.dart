import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../pages/user_profile_page.dart';
import '../pages/post_page.dart';
import '../pages/edit_post_page.dart';

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

  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: const Text('Are you sure you want to permanently delete this post?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _firestoreService.deletePost(postId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.post.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? 'No Content';
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    final String? imageUrl = data['imageUrl'];

    String businessName = 'Anonymous Business';
    String? businessPhotoUrl;
    String businessId = data['businessId'] ?? '';
    if (_businessProfile != null && _businessProfile!.exists) {
      final businessData = _businessProfile!.data() as Map<String, dynamic>;
      businessName = businessData['name'] ?? 'Unnamed Business';
      businessPhotoUrl = businessData['photoUrl'];
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = currentUserId != null && currentUserId == businessId;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error_outline, color: Colors.red));
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(),
                  if (!_isLoading)
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
                            Expanded(
                              child: Text(
                                businessName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isOwner)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditPostPage(post: widget.post),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(context, widget.post.id),
                                  ),
                                ],
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

                 
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // StreamBuilder for the like button state
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
                          // StreamBuilder for the reaction count
                          StreamBuilder<int>(
                            stream: _firestoreService.getPostReactionCount(widget.post.id),
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
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
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

