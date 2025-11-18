import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/pages/business_profile_page.dart';
import 'package:flutter_app/pages/customer_profile_page.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'full_screen_image_viewer.dart';
import '../services/logging_service.dart';

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
      return Colors.grey.shade500;
    default:
      return Colors.transparent;
  }
}

class PostPage extends StatefulWidget {
  final PostModel post;

  const PostPage({super.key, required this.post});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final LoggingService _loggingService = LoggingService();

  UserModel? _businessProfile;
  bool _isLoading = true;

  bool _isExpanded = false;
  static const int _characterLimit = 150;

  @override
  void initState() {
    super.initState();
    _fetchBusinessProfile();

    _loggingService.logAnalyticsEvent(
      eventName: 'post_view',
      parameters: {
        'post_id': widget.post.id,
        'post_name': widget.post.title,
        'business_id': widget.post.businessId,
      },
    );
  }

  Future<void> _fetchBusinessProfile() async {
    try {
      if (widget.post.businessId.isNotEmpty) {
        final profile =
            await _firestoreService.getUserProfile(widget.post.businessId);
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

  // Helper function to handle navigation
  void _navigateToUserProfile(String userId) async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId == currentUserId) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // Check user model role
    if (_businessProfile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _businessProfile!.isBusiness
              ? BusinessProfilePage(
                  userId: userId, scaffoldKey: GlobalKey<ScaffoldState>())
              : CustomerProfilePage(
                  userId: userId, scaffoldKey: GlobalKey<ScaffoldState>()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = widget.post.formattedDate;
    final bool isLongText = widget.post.content.length > _characterLimit;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_businessProfile != null)
                  GestureDetector(
                    onTap: () {
                      _loggingService.logAnalyticsEvent(
                        eventName: 'click_through',
                        parameters: {
                          'business_id': _businessProfile!.uid,
                        },
                      );
                      _navigateToUserProfile(_businessProfile!.uid);
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: _businessProfile!.photoUrl != null
                                ? NetworkImage(_businessProfile!.photoUrl!)
                                : null,
                            radius: 22,
                            child: _businessProfile!.photoUrl == null
                                ? const Icon(Icons.store, size: 22)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _businessProfile!.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  if (_businessProfile!.verificationStatus == 'accepted')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6.0),
                                      child: Icon(
                                        Icons.verified,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 18.0, 
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                'Posted on $formattedDate',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (widget.post.tag != null &&
                              widget.post.tag!.isNotEmpty)
                            Chip(
                              label: Text(widget.post.tag!),
                              backgroundColor: _getTagColor(widget.post.tag),
                              labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 2.0),
                              shape: const StadiumBorder(),
                            ),
                        ],
                      ),
                    ),
                  ),

                const Divider(height: 24),

                Text(
                  widget.post.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                // Image
                if (widget.post.imageUrl != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: widget.post.id,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageViewer(
                                    imageUrl: widget.post.imageUrl!,
                                    tag: widget.post.id,
                                  ),
                                ),
                              );
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: AspectRatio(
                                aspectRatio:
                                    widget.post.imageAspectRatio ?? 16 / 9,
                                child: Image.network(
                                  widget.post.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                        child: Icon(Icons.error_outline,
                                            color: Colors.red, size: 50));
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLongText && !_isExpanded
                          ? '${widget.post.content.substring(0, _characterLimit)}...'
                          : widget.post.content,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.6, fontSize: 16),
                    ),
                    if (isLongText)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _isExpanded ? 'Read Less' : 'Read More',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),

                // Likes
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      StreamBuilder<bool>(
                        stream:
                            _firestoreService.hasUserReacted(widget.post.id),
                        builder: (context, snapshot) {
                          final hasReacted = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              hasReacted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: hasReacted ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              _firestoreService
                                  .togglePostReaction(widget.post.id);
                              _loggingService.logAnalyticsEvent(
                                eventName: hasReacted
                                    ? 'post_reaction_removed'
                                    : 'post_reaction_added',
                                parameters: {
                                  'post_id': widget.post.id,
                                  'business_id': widget.post.businessId,
                                },
                              );
                            },
                          );
                        },
                      ),
                      StreamBuilder<int>(
                        stream: _firestoreService
                            .getPostReactionCount(widget.post.id),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count likes',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
