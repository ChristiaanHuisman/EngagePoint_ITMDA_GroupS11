import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/review_card.dart';
import 'write_review_page.dart'; // Import the WriteReviewPage

class BusinessProfilePage extends StatefulWidget {
  final String businessId;

  const BusinessProfilePage({super.key, required this.businessId});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<bool> _isSelected = [true, false]; // [Posts, Reviews]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Profile"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestoreService.getUserProfile(widget.businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile."));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Business profile not found."));
          }

          final businessData = snapshot.data!.data() as Map<String, dynamic>;
          final String businessName = businessData['name'] ?? 'Unnamed Business';
          final String? businessPhotoUrl = businessData['photoUrl'];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: businessPhotoUrl != null ? NetworkImage(businessPhotoUrl) : null,
                        child: businessPhotoUrl == null ? const Icon(Icons.store, size: 50) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        businessName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<int>(
                            stream: _firestoreService.getFollowerCount(widget.businessId),
                            builder: (context, countSnapshot) {
                              final count = countSnapshot.data ?? 0;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    count.toString(),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Text("Followers"),
                                ],
                              );
                            },
                          ),
                          StreamBuilder<Map<String, double>>(
                            stream: _firestoreService.getReviewStats(widget.businessId),
                            builder: (context, statsSnapshot) {
                              if (!statsSnapshot.hasData) return const SizedBox(width: 80);
                              final count = statsSnapshot.data?['count']?.toInt() ?? 0;
                              final average = statsSnapshot.data?['average'] ?? 0.0;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 24),
                                      const SizedBox(width: 4),
                                      Text(
                                        average.toStringAsFixed(1),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text("$count Reviews"),
                                ],
                              );
                            },
                          ),
                          StreamBuilder<bool>(
                            stream: _firestoreService.isFollowing(widget.businessId),
                            builder: (context, isFollowingSnapshot) {
                              final isFollowing = isFollowingSnapshot.data ?? false;
                              final isOwnProfile = FirebaseAuth.instance.currentUser?.uid == widget.businessId;

                              return ElevatedButton.icon(
                                onPressed: isOwnProfile ? null : () {
                                  if (isFollowing) {
                                    _firestoreService.unfollowBusiness(widget.businessId);
                                  } else {
                                    _firestoreService.followBusiness(widget.businessId);
                                  }
                                },
                                icon: Icon(isFollowing ? Icons.check : Icons.add, size: 16),
                                label: Text(isFollowing ? "Following" : "Follow"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  backgroundColor: isFollowing ? Colors.grey : Theme.of(context).colorScheme.primary,
                                  foregroundColor: isFollowing ? Colors.black : Theme.of(context).colorScheme.onPrimary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: ToggleButtons(
                      isSelected: _isSelected,
                      onPressed: (int index) {
                        setState(() {
                          for (int i = 0; i < _isSelected.length; i++) {
                            _isSelected[i] = i == index;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(30.0),
                      borderColor: Colors.grey.shade300,
                      selectedBorderColor: Theme.of(context).colorScheme.primary,
                      constraints: const BoxConstraints(minHeight: 38.0, minWidth: 100.0),
                      selectedColor: Colors.white,
                      fillColor: Theme.of(context).colorScheme.primary,
                      color: Theme.of(context).colorScheme.primary,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Posts')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Reviews')),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Divider(height: 1, color: Colors.grey.shade300),
              )),

              if (_isSelected[0])
                _buildPostsList()
              else
                _buildReviewsList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getPostsForBusiness(widget.businessId),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())));
        }
        if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("This business hasn't made any posts yet."),
              ),
            ),
          );
        }

        final posts = postSnapshot.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return PostCard(post: posts[index]);
            },
            childCount: posts.length,
          ),
        );
      },
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getReviewsForBusiness(widget.businessId),
      builder: (context, reviewSnapshot) {
        if (reviewSnapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())));
        }
        if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    const Text("No reviews yet. Be the first!"),
                    const SizedBox(height: 10),
                    // --- FIX APPLIED HERE ---
                    TextButton(
                      onPressed: () {
                        // Navigate to the WriteReviewPage, passing the business ID.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WriteReviewPage(businessId: widget.businessId),
                          ),
                        );
                      },
                      child: const Text("Write a Review"),
                    ),
                    // --- END OF FIX ---
                  ],
                ),
              ),
            ),
          );
        }

        final reviews = reviewSnapshot.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ReviewCard(review: reviews[index]),
              );
            },
            childCount: reviews.length,
          ),
        );
      },
    );
  }
}

