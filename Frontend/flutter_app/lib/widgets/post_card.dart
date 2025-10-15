import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart'; // ADDED: Import the PostModel
import '../services/firestore_service.dart';
import '../pages/user_profile_page.dart';
import '../pages/post_page.dart';
import '../pages/edit_post_page.dart';

class PostCard extends StatelessWidget {
  // CHANGED: The post is now a PostModel, not a QueryDocumentSnapshot.
  final PostModel post;
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
    // REMOVED: Manual data extraction is no longer needed.
    // We can now access properties directly from the `post` object.
    final String formattedDate = DateFormat('MMM dd, yyyy').format(post.createdAt.toDate());

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
              // NOTE: PostPage will need to be updated to accept a PostModel.
              builder: (context) => PostPage(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostHeader(
                businessId: post.businessId, // CHANGED
                onDelete: () => _showDeleteConfirmation(context, post.id), // CHANGED
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // NOTE: EditPostPage will need to be updated to accept a PostModel.
                      builder: (context) => EditPostPage(post: post),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title, // CHANGED
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.content, // CHANGED
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (post.imageUrl != null) // CHANGED
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post.imageUrl!, // CHANGED
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey[200],
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 90,
                              height: 90,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error_outline),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      StreamBuilder<bool>(
                        stream: _firestoreService.hasUserReacted(post.id), // CHANGED
                        builder: (context, snapshot) {
                          final hasReacted = snapshot.data ?? false;
                          return IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              hasReacted ? Icons.favorite : Icons.favorite_border,
                              color: hasReacted ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => _firestoreService.togglePostReaction(post.id), // CHANGED
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      StreamBuilder<int>(
                        stream: _firestoreService.getPostReactionCount(post.id), // CHANGED
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
      ),
    );
  }
}

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

    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getUserProfile(businessId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(
            children: [
              CircleAvatar(backgroundColor: Colors.transparent, radius: 20),
              SizedBox(width: 12),
              Text('Loading...'),
            ],
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Unknown Business');
        }

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
                backgroundImage: businessPhotoUrl != null ? NetworkImage(businessPhotoUrl) : null,
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