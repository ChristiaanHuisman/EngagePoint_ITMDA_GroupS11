import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/write_review_page.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/review_card.dart';
import 'edit_profile_page.dart';

// Level struct
class Level {
  final int level;
  final String name;
  final int pointsRequired;
  Level(
      {required this.level, required this.name, required this.pointsRequired});
}

class CustomerProfilePage extends StatefulWidget {
  final String userId;
  final bool isMainPage;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CustomerProfilePage({
    super.key,
    required this.userId,
    this.isMainPage = false,
    required this.scaffoldKey,
  });

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();

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

        if (user == null || user.isBusiness) {
          return const Scaffold(
              body: Center(child: Text("Customer profile not found.")));
        }

        final bool canViewContent = !user.isPrivate || isOwnProfile;

        // Customer has 2 tabs: Reviews & Rewards
        return DefaultTabController(
            length: 2,
            child: Scaffold(
                appBar: AppBar(
                  title: Text(isOwnProfile ? "My Profile" : user.name),
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
                                onPressed: () => widget.scaffoldKey.currentState
                                    ?.openDrawer(),
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
                            child: _buildProfileHeader(
                                context, user, isOwnProfile)),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _TabBarHeaderDelegate(
                            TabBar(
                              tabs: const [
                                Tab(
                                    icon: Icon(Icons.reviews_outlined),
                                    text: 'Reviews'),
                                Tab(
                                    icon: Icon(Icons.emoji_events_outlined),
                                    text: 'Rewards'),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                    body: canViewContent
                        ? TabBarView(
                            children: [
                              _ReviewsTab(
                                userId: widget.userId,
                                isCustomerView: true,
                                firestoreService: _firestoreService,
                                profileOwnerUser: user,
                              ),
                              _RewardsTab(
                                user: user,
                                getLevelData: _getLevelData,
                                firestoreService: _firestoreService,
                              ),
                            ],
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                "This profile is private.",
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                  ),
                )));
      },
    );
  }

  //  Helper Widgets
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
                ? const Icon(Icons.person, size: 60)
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
          const SizedBox(height: 16),
        ],
      ),
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

class _ReviewsTab extends StatelessWidget {
  final String userId;
  final bool isCustomerView;
  final FirestoreService firestoreService;
  final UserModel profileOwnerUser;
  const _ReviewsTab(
      {required this.userId,
      required this.isCustomerView,
      required this.firestoreService,
      required this.profileOwnerUser});
  @override
  Widget build(BuildContext context) {
    final bool canWriteReview =
        FirebaseAuth.instance.currentUser?.uid != userId;

    // Private profile check
    final bool canViewContent = !profileOwnerUser.isPrivate ||
        FirebaseAuth.instance.currentUser?.uid == userId;

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

              // Handle private profile
              if (isCustomerView && !canViewContent) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("This profile is private.",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ),
                );
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
