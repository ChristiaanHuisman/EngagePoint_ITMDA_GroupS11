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
import '../widgets/app_drawer.dart';

// Level struct
class Level {
  final int level;
  final String name;
  final int pointsRequired;

  Level(
      {required this.level, required this.name, required this.pointsRequired});
}

// Main StatefulWidget
class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final LoggingService _loggingService = LoggingService();

  // Level data
  final List<Level> _levels = [
    Level(level: 1, name: 'Bronze', pointsRequired: 0),
    Level(level: 2, name: 'Silver', pointsRequired: 500),
    Level(level: 3, name: 'Gold', pointsRequired: 1500),
    Level(level: 4, name: 'Platinum', pointsRequired: 3000),
    Level(level: 5, name: 'Diamond', pointsRequired: 5000),
  ];
  Map<String, dynamic> _getLevelData(int points) {
    Level currentLevel = _levels.first;
    for (var level in _levels.reversed) {
      if (points >= level.pointsRequired) {
        currentLevel = level;
        break;
      }
    }
    int nextLevelIndex = currentLevel.level;
    Level? nextLevel =
        (nextLevelIndex < _levels.length) ? _levels[nextLevelIndex] : null;
    if (nextLevel == null) {
      return {
        'currentLevel': currentLevel,
        'nextLevel': null,
        'progress': 1.0,
        'pointsToNextLevel': 0
      };
    }
    final int pointsInCurrent = points - currentLevel.pointsRequired;
    final int pointsForNext =
        nextLevel.pointsRequired - currentLevel.pointsRequired;
    final double progress =
        pointsForNext == 0 ? 1.0 : pointsInCurrent / pointsForNext;
    return {
      'currentLevel': currentLevel,
      'nextLevel': nextLevel,
      'progress': progress.clamp(0.0, 1.0),
      'pointsToNextLevel': nextLevel.pointsRequired - points
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isOwnProfile = currentUserId == widget.userId;

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserProfileStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const Scaffold(
              body: Center(child: Text("Error loading profile.")));
        }

        final UserModel? user = snapshot.data;

        if (user == null) {
          return const Scaffold(
              body: Center(child: Text("User profile not found.")));
        }

        if (user.isBusiness && !isOwnProfile) {
          _loggingService.logAnalyticsEvent(
            eventName: 'View_business_profile',
            parameters: {
              'viewer_id': currentUserId ?? 'unknown',
              'viewed_business_id': widget.userId
            },
          );
        }

        return DefaultTabController(
            length: user.isBusiness ? 2 : 2,
            child: Scaffold(
                appBar: AppBar(
                  title: Text(isOwnProfile ? "My Profile" : "Profile"),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  leading: Navigator.canPop(context)
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context))
                      : (isOwnProfile
                          ? Builder(
                              builder: (context) => IconButton(
                                  icon: const Icon(Icons.menu),
                                  onPressed: () =>
                                      Scaffold.of(context).openDrawer()))
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
                drawer: isOwnProfile ? const AppDrawer() : null,
                body: SafeArea(
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return <Widget>[
                        SliverToBoxAdapter(
                            child: _buildProfileHeader(
                                context, user, isOwnProfile)),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabBarHeaderDelegate(
                            TabBar(
                              tabs: user.isBusiness
                                  ? const [
                                      Tab(
                                          icon: Icon(Icons.post_add_outlined),
                                          text: 'Posts'),
                                      Tab(
                                          icon: Icon(Icons.reviews_outlined),
                                          text: 'Reviews')
                                    ]
                                  : const [
                                      Tab(
                                          icon: Icon(Icons.reviews_outlined),
                                          text: 'Reviews'),
                                      Tab(
                                          icon:
                                              Icon(Icons.emoji_events_outlined),
                                          text: 'Rewards')
                                    ],
                              indicatorColor:
                                  Theme.of(context).colorScheme.primary,
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Colors.grey,
                            ),
                          ),
                        ),
                      ];
                    },
                    body: SafeArea(
                      child: TabBarView(
                        children: user.isBusiness
                            ? [
                                _PostsTab(
                                    userId: widget.userId,
                                    firestoreService: _firestoreService),
                                _ReviewsTab(
                                    userId: widget.userId,
                                    isCustomerView: false,
                                    firestoreService: _firestoreService),
                              ]
                            : [
                                _ReviewsTab(
                                    userId: widget.userId,
                                    isCustomerView: true,
                                    firestoreService: _firestoreService),
                                _RewardsTab(
                                    user: user,
                                    getLevelData: _getLevelData,
                                    firestoreService: _firestoreService),
                              ],
                      ),
                    ),
                  ),
                )));
      },
    );
  }

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
                ? Icon(user.isBusiness ? Icons.store : Icons.person, size: 60)
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
          if (user.isBusiness &&
              user.businessType != null &&
              user.businessType!.isNotEmpty)
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
          if (user.isBusiness)
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
                            icon:
                                const Icon(Icons.dashboard_outlined, size: 16),
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
                  const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Store Locations')),
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
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) => false;
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

class _RewardsTab extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> Function(int) getLevelData;
  final FirestoreService firestoreService;

  const _RewardsTab(
      {required this.user,
      required this.getLevelData,
      required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    final int points = user.points;
    final levelData = getLevelData(points);
    final Level currentLevel = levelData['currentLevel'];
    final double progress = levelData['progress'];
    final Level? nextLevel = levelData['nextLevel'];
    final int pointsToNext = levelData['pointsToNextLevel'];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Current Rank",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              currentLevel.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(10),
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              nextLevel == null
                  ? "Max Level Achieved!"
                  : "Level ${currentLevel.level} → ${nextLevel.level} ($pointsToNext pts to next)",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
