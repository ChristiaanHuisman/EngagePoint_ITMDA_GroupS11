import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/logging_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../pages/user_profile_page.dart';
import '../pages/post_page.dart';
import '../pages/edit_post_page.dart';

Color _getTagColor(String? tag) {
  switch (tag) {
    case 'Promotion':
      return Colors.blue.shade300;
    case 'Sale':
      return Colors.green.shade300;
    case 'Event':
      return Colors.orange.shade300;
    case 'New Stock':
      return Colors.purple.shade300;
    case 'Update':
      return Colors.red.shade500;
    default:
      return Colors.transparent;
  }
}

class PostCard extends StatelessWidget {
  final PostModel post;
  final FirestoreService _firestoreService = FirestoreService();
  final LoggingService _loggingService = LoggingService();

  PostCard({super.key, required this.post});

  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: const Text(
              'Are you sure you want to permanently delete this post?'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostHeader(
                post: post,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.content,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (post.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post.imageUrl!,
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
                        stream: _firestoreService.hasUserReacted(post.id),
                        builder: (context, snapshot) {
                          final hasReacted = snapshot.data ?? false;
                          return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                hasReacted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: hasReacted ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => {
                                    _firestoreService
                                        .togglePostReaction(post.id),
                                    _loggingService.logAnalyticsEvent(
                                      eventName: hasReacted
                                          ? 'post_reaction_removed'
                                          : 'post_reaction_added',
                                      parameters: {
                                        'post_id': post.id,
                                        'business_id': post.businessId,
                                      },
                                    ),
                                  });
                        },
                      ),
                      const SizedBox(width: 4),
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
                    post.formattedDate,
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
  final PostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final FirestoreService _firestoreService = FirestoreService();

  PostHeader({
    required this.post,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner =
        currentUserId != null && currentUserId == post.businessId;

    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUserProfile(post.businessId),
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

        final business = snapshot.data;
        if (business == null) {
          return const Text('Unknown Business');
        }

        return GestureDetector(
          onTap: () {
            final String targetUserId = post.businessId;
            if (targetUserId.isNotEmpty && targetUserId == currentUserId) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            } else if (targetUserId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: targetUserId),
                ),
              );
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: business.photoUrl != null
                    ? NetworkImage(business.photoUrl!)
                    : null,
                radius: 20,
                child: business.photoUrl == null
                    ? const Icon(Icons.store, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  business.name, // Direct access
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (post.tag != null && post.tag!.isNotEmpty)
                Chip(
                  label: Text(post.tag!),
                  backgroundColor: _getTagColor(post.tag),
                  labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 2.0),
                  shape: const StadiumBorder(),
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
