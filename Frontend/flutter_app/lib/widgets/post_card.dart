import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../pages/user_profile_page.dart';
import '../pages/post_page.dart';
import '../pages/edit_post_page.dart';

// FIX: The PostCard is now a StatelessWidget.
// This simplifies the widget and removes the problematic state management that was
// causing the wrong business banner to appear when scrolling. The responsibility
// of fetching and displaying the business information is now handled by the new
// self-contained `PostHeader` widget below.
class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  final FirestoreService _firestoreService = FirestoreService();

  PostCard({super.key, required this.post});

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
    final Map<String, dynamic> data = post.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? 'No Content';
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    final String? imageUrl = data['imageUrl'];
    final String businessId = data['businessId'] ?? '';

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
              builder: (context) => PostPage(post: post),
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
                  // THE FIX: Using the new self-contained PostHeader widget.
                  // This widget fetches its own data, making it immune to the
                  // ListView recycling issue that caused the wrong banner to show.
                  PostHeader(
                    businessId: businessId,
                    onDelete: () => _showDeleteConfirmation(context, post.id),
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPostPage(post: post),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

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
                            stream: _firestoreService.hasUserReacted(post.id),
                            builder: (context, snapshot) {
                              final hasReacted = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  hasReacted ? Icons.favorite : Icons.favorite_border,
                                  color: hasReacted ? Colors.red : Colors.grey,
                                ),
                                onPressed: () {
                                  _firestoreService.togglePostReaction(post.id);
                                },
                              );
                            },
                          ),
                          // StreamBuilder for the reaction count
                          StreamBuilder<int>(
                            stream: _firestoreService.getPostReactionCount(post.id),
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

// ADDITION: New self-contained widget to safely display post headers.
class PostHeader extends StatelessWidget {
  final String businessId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final FirestoreService _firestoreService = FirestoreService();

  PostHeader({
    required this.businessId,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = currentUserId != null && currentUserId == businessId;

    // FutureBuilder fetches the data and rebuilds this widget when it arrives.
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getUserProfile(businessId),
      builder: (context, snapshot) {
        // While the data is loading, show a simple placeholder.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.transparent),
              const SizedBox(width: 12),
              const Text('Loading...'),
            ],
          );
        }

        // If the fetch failed or the business doesn't exist, show an error state.
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Unknown Business');
        }

        // If the data is here, extract it and display it.
        var businessData = snapshot.data!.data() as Map<String, dynamic>;
        final String businessName = businessData['name'] ?? 'Unnamed Business';
        final String? businessPhotoUrl = businessData['photoUrl'];

        return GestureDetector(
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
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}