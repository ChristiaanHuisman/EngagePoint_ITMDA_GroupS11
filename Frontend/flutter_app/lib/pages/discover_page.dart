import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';


class DiscoverPageWrapper extends StatelessWidget {
  final String searchQuery;
  final Function(BuildContext, String) onNavigate;

  const DiscoverPageWrapper({
    super.key,
    required this.searchQuery,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        const DiscoverFeed(), 
        if (searchQuery.trim().isNotEmpty)
          DiscoverSearchResults( 
            searchQuery: searchQuery,
            onNavigate: onNavigate,
          ),
      ],
    );
  }
}


class DiscoverFeed extends StatelessWidget {
  const DiscoverFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<PostModel>>(
      stream: firestoreService.getAllPosts(),
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (postSnapshot.hasError) {
          return const Center(child: Text("Something went wrong."));
        }
        if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
          return const Center(child: Text("No posts to discover yet."));
        }

        final posts = postSnapshot.data!
            .where((post) => post.businessId != currentUserId)
            .toList();

        if (posts.isEmpty) {
          return const Center(
              child: Text("No other businesses have posted yet."));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
    );
  }
}


class DiscoverSearchResults extends StatelessWidget {
  final String searchQuery;
  final Function(BuildContext, String) onNavigate;
  final FirestoreService _firestoreService = FirestoreService();

  DiscoverSearchResults({
    super.key,
    required this.searchQuery,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, 
      child: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.searchBusinesses(searchQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) {
            return const ListTile(title: Text('Error searching businesses.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const ListTile(title: Text('No businesses found.'));
          }

          final results = snapshot.data!;

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final UserModel business = results[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: business.photoUrl != null
                      ? NetworkImage(business.photoUrl!)
                      : null,
                  child: business.photoUrl == null
                      ? const Icon(Icons.store)
                      : null,
                ),
                title: Text(business.name),
                onTap: () {

                  onNavigate(context, business.uid);
                },
              );
            },
          );
        },
      ),
    );
  }
}