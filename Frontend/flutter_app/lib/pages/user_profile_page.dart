import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/review_card.dart';
import 'business_dashboard_page.dart';
import 'edit_profile_page.dart';
import 'manage_locations_page.dart';
import 'write_review_page.dart';
import '../services/logging_service.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<bool> _isSelected = [true, false];
  final LoggingService _loggingService = LoggingService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? "Your Profile" : "Profile"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final doc = await _firestoreService.getUserProfile(widget.userId);
                if (!mounted) return;
                if (doc.exists) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        userData: doc.data() as Map<String, dynamic>,
                        userId: widget.userId,
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile."));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User profile not found."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String name = userData['name'] ?? 'Unnamed User';
          final String? photoUrl = userData['photoUrl'];
          final String role = userData['role'] ?? 'customer';
          final String? description = userData['description'];
          final String? businessType = userData['businessType'];

          _loggingService.logAnalyticsEvent(  //analytics logging
          eventName: 'View_business_profile',
            parameters: {
              'viewer_id': currentUserId ?? 'unknown',
              'viewed_business_id': widget.userId,
              
        },
    );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null ? Icon(role == 'business' ? Icons.store : Icons.person, size: 60) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Description is now before the business type
                      if (description != null && description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      
                      // THE FIX IS HERE: The business type Chip is now after the description.
                      if (role == 'business' && businessType != null && businessType.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Chip(
                            label: Text(businessType),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSecondaryContainer
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),

                      const SizedBox(height: 16),
                      if (role == 'business')
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatColumn("Followers", _firestoreService.getFollowerCount(widget.userId)),
                                _buildReviewStatColumn(widget.userId),
                                
                                if (isOwnProfile)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const BusinessDashboardPage()),
                                      );
                                    },
                                    icon: const Icon(Icons.dashboard_outlined, size: 16),
                                    label: const Text('Dashboard'),
                                  )
                                else 
                                  _buildFollowButton(widget.userId),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: isOwnProfile
                                  ? _buildManageLocationsButton(context)
                                  : _buildLocationsButton(context, widget.userId),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const Divider(height: 1),
                    _buildContentHeader(context, role, isOwnProfile),
                    Divider(height: 1, color: Colors.grey.shade300),
                  ],
                ),
              ),
              
              _buildContentBody(role, isOwnProfile),
            ],
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildManageLocationsButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageLocationsPage()),
        );
      },
      icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
      label: const Text('Manage Store Locations'),
    );
  }

  Widget _buildLocationsButton(BuildContext context, String businessId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getLocations(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final locations = snapshot.data!.docs;
        
        return OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Store Locations', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final location = locations[index];
                          final String name = location['name'];
                          final String address = location['address'];
                          return ListTile(
                            leading: const Icon(Icons.store_mall_directory_outlined),
                            title: Text(name),
                            subtitle: Text(address),
                            onTap: () async {
                              final Uri mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
                              if (await canLaunchUrl(mapsUrl)) {
                                await launchUrl(mapsUrl);
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open map.')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
          icon: const Icon(Icons.store_outlined, size: 16),
          label: Text('View ${locations.length} Locations'),
        );
      },
    );
  }

  Widget _buildContentHeader(BuildContext context, String role, bool isOwnProfile) {
    if (role == 'business') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ToggleButtons(
            isSelected: _isSelected,
            onPressed: (int index) {
              setState(() {
                _isSelected[0] = index == 0;
                _isSelected[1] = index == 1;
              });
            },
            borderRadius: BorderRadius.circular(30.0),
            constraints: const BoxConstraints(minHeight: 38.0, minWidth: 100.0),
            selectedColor: Colors.white,
            fillColor: Theme.of(context).colorScheme.primary,
            borderColor: Colors.grey.shade300,
            selectedBorderColor: Theme.of(context).colorScheme.primary,
            children: const [Text('Posts'), Text('Reviews')],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          isOwnProfile ? "Your Reviews" : "Reviews Written",
          style: Theme.of(context).textTheme.titleLarge
        ),
      );
    }
  }

  Widget _buildContentBody(String role, bool isOwnProfile) {
    if (role == 'business') {
      return _isSelected[0] ? _buildPostsList() : _buildReviewsList(isOwnProfile: isOwnProfile, role: role);
    } else {
      return _buildReviewsList(isOwnProfile: isOwnProfile, role: role);
    }
  }

  Widget _buildStatColumn(String label, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count.toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label),
          ],
        );
      },
    );
  }

  Widget _buildReviewStatColumn(String businessId) {
    return StreamBuilder<Map<String, double>>(
      stream: _firestoreService.getReviewStats(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final count = snapshot.data?['count']?.toInt() ?? 0;
        final average = snapshot.data?['average'] ?? 0.0;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 4),
                Text(average.toStringAsFixed(1), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            Text("$count Reviews"),
          ],
        );
      },
    );
  }

  Widget _buildFollowButton(String businessId) {
    return StreamBuilder<bool>(
      stream: _firestoreService.isFollowing(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ElevatedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text("Loading"),
          );
        }

        final isFollowing = snapshot.data!;

        return ElevatedButton.icon(
          onPressed: () {
            if (isFollowing) {
              _firestoreService.unfollowBusiness(businessId);
            } else {
              _firestoreService.followBusiness(businessId);
            }
          },
          icon: Icon(isFollowing ? Icons.check : Icons.add, size: 16),
          label: Text(isFollowing ? "Following" : "Follow"),
          style: null,
        );
      },
    );
    
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getPostsForBusiness(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator())));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No posts yet."))));
        
        final posts = snapshot.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) => PostCard(post: posts[index]), childCount: posts.length),
        );
      },
    );
  }

  Widget _buildReviewsList({required bool isOwnProfile, required String role}) {
    final bool isCustomerView = role == 'customer';
    final bool canWriteReview = !isOwnProfile && role == 'business';
  
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if(role == 'business')
                  Text( "Customer Reviews", style: Theme.of(context).textTheme.titleLarge),
                if (canWriteReview)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WriteReviewPage(businessId: widget.userId),
                        ),
                      );
                    },
                    child: const Text("Write a Review"),
                  ),
              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: isCustomerView
              ? _firestoreService.getReviewsForCustomer(widget.userId)
              : _firestoreService.getReviewsForBusiness(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              debugPrint("Error loading reviews: ${snapshot.error}");
              return const SliverToBoxAdapter(child: Center(child: Text("Error loading reviews.")));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(isCustomerView ? "This user hasn't written any reviews." : "No reviews yet."),
                  ),
                ),
              );
            }

            final reviews = snapshot.data!.docs;
            return SliverList.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ReviewCard(review: reviews[index], showBusinessName: isCustomerView),
                );
              },
            );
          },
        ),
      ],
    );
  }
}