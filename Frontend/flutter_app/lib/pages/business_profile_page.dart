import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/location_model.dart';
import '../models/post_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/review_card.dart';
import 'business_dashboard_page.dart';
import 'edit_profile_page.dart';
import 'manage_locations_page.dart';
import 'write_review_page.dart';
import '../services/logging_service.dart';

class BusinessProfilePage extends StatefulWidget {
  final String userId;
  final bool isMainPage;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const BusinessProfilePage({
    super.key,
    required this.userId,
    this.isMainPage = false,
    required this.scaffoldKey,
  });

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final LoggingService _loggingService = LoggingService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwnProfile = currentUserId == widget.userId;

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserProfileStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Error loading profile.")));
        }

        final UserModel? user = snapshot.data;

        if (user == null || !user.isBusiness) {
          return const Scaffold(body: Center(child: Text("Business profile not found.")));
        }

        if (!isOwnProfile) {
          _loggingService.logAnalyticsEvent(
            eventName: 'View_business_profile',
            parameters: {
              'viewer_id': currentUserId ?? 'unknown',
              'viewed_business_id': widget.userId
            },
          );
        }
        

        
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(isOwnProfile ? "My Business Profile" : user.name),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              
              
              leading: !widget.isMainPage
                  ? IconButton( 
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context))
                  : (isOwnProfile
                      ? Builder( 
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
                          ),
                        )
                      : null),

              actions: [
                if (isOwnProfile)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfilePage(user: user)),
                      );
                    },
                  ),
              ],
            ),
            


            
            
            body: SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverToBoxAdapter(
                        child: _buildProfileHeader(context, user, isOwnProfile)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarHeaderDelegate(
                        TabBar(
                          tabs: const [
                            Tab(
                                icon: Icon(Icons.post_add_outlined),
                                text: 'Posts'),
                            Tab(
                                icon: Icon(Icons.reviews_outlined),
                                text: 'Reviews'),
                          ],
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _PostsTab(
                        userId: widget.userId,
                        firestoreService: _firestoreService),
                    _ReviewsTab(
                        userId: widget.userId,
                        isCustomerView: false,
                        firestoreService: _firestoreService),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper Widgets 
  Widget _buildProfileHeader(
      BuildContext context, UserModel user, bool isOwnProfile) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.store, size: 60)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          if (user.description != null && user.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(user.description!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600])),
            ),
          if (user.businessType != null && user.businessType!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: Text(user.businessType!),
                labelStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSecondaryContainer),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn("Followers",
                      _firestoreService.getFollowerCount(widget.userId)),
                  _buildReviewStatColumn(widget.userId),
                  isOwnProfile
                      ? ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const BusinessDashboardPage())),
                          icon: const Icon(Icons.dashboard_outlined, size: 16),
                          label: const Text('Dashboard'))
                      : _buildFollowButton(widget.userId),
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
    );
  }

  Widget _buildManageLocationsButton(BuildContext context) =>
      OutlinedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManageLocationsPage())),
          icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
          label: const Text('Manage Store Locations'));

  Widget _buildLocationsButton(BuildContext context, String businessId) {
    return StreamBuilder<List<LocationModel>>(
      stream: _firestoreService.getLocations(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final locations = snapshot.data!;
        return OutlinedButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Store Locations',
                          style: Theme.of(context).textTheme.titleLarge)),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return ListTile(
                          leading:
                              const Icon(Icons.store_mall_directory_outlined),
                          title: Text(location.name),
                          subtitle: Text(location.address),
                          onTap: () async {
                            final Uri mapsUrl = Uri.parse(
                                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location.address)}');
                            if (await canLaunchUrl(mapsUrl)) {
                              await launchUrl(mapsUrl);
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Could not open map.')));
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.store_outlined, size: 16),
          label: Text('View ${locations.length} Locations'),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Column(
          children: [
            Text(count.toString(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
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
        final avg = snapshot.data?['average'] ?? 0.0;
        return Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(avg.toStringAsFixed(1),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
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
        final isFollowing = snapshot.data ?? false;
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
        );
      },
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _TabBarHeaderDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(
          color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) => true;
}

class _PostsTab extends StatelessWidget {
  final String userId;
  final FirestoreService firestoreService;
  const _PostsTab({required this.userId, required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: firestoreService.getPostsForBusiness(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No posts yet."));
        }
        final posts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(0),
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  final String userId;
  final bool isCustomerView;
  final FirestoreService firestoreService;
  const _ReviewsTab(
      {required this.userId,
      required this.isCustomerView,
      required this.firestoreService});
  @override
  Widget build(BuildContext context) {
    final bool canWriteReview =
        FirebaseAuth.instance.currentUser?.uid != userId;
    return Column(
      children: [
        if (!isCustomerView)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Reviews", style: Theme.of(context).textTheme.titleLarge),
                if (canWriteReview)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  WriteReviewPage(businessId: userId)));
                    },
                    child: const Text("Write a Review"),
                  ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ReviewModel>>(
            stream: isCustomerView
                ? firestoreService.getReviewsForCustomer(userId)
                : firestoreService.getReviewsForBusiness(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error loading reviews."));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(isCustomerView
                      ? "This user hasn't written any reviews."
                      : "No reviews yet."),
                );
              }
              final reviews = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: reviews.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ReviewCard(
                      review: reviews[index], showBusinessName: isCustomerView),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}