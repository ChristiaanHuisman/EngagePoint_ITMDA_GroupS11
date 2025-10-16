import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _businessId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_businessId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Not logged in.")),
      );
    }

    return DefaultTabController(
      length: 2, // Engagement + Sentiment
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Engagement'),
              Tab(icon: Icon(Icons.emoji_emotions_outlined), text: 'Sentiment'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _buildEngagementView(),
            _buildSentimentView(),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engagement Analytics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStatCard(
            icon: Icons.people,
            label: 'Total Followers',
            stream: _firestoreService.getFollowerCount(_businessId!),
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.favorite,
            label: 'Total Likes on All Posts',
            future: _firestoreService.getTotalLikesForBusiness(_businessId),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            icon: Icons.reviews,
            label: 'Total Customer Reviews',
            future: _firestoreService.getTotalReviewsForBusiness(_businessId),
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

Widget _buildSentimentView() {
  final currentUser = FirebaseAuth.instance.currentUser;
  final businessId = currentUser?.uid ?? '';
  final statsFuture = FirestoreService().getReviewSentimentStats(businessId);

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Sentiment Analysis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, int>>(
          future: statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data ?? {'positive': 0, 'negative': 0, 'neutral': 0};

            return Column(
              children: [
                _buildStatCard(
                  icon: Icons.thumb_up,
                  label: 'Positive Reviews',
                  future: Future.value(stats['positive']),
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.thumb_down,
                  label: 'Negative Reviews',
                  future: Future.value(stats['negative']),
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.remove,
                  label: 'Neutral Reviews',
                  future: Future.value(stats['neutral']),
                  color: Colors.grey,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}


  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Color color,
    Stream<int>? stream,
    Future<int>? future,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16)),
                if (stream != null)
                  StreamBuilder<int>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('...');
                      return Text(snapshot.data.toString(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold));
                    },
                  )
                else if (future != null)
                  FutureBuilder<int>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Text('...');
                      return Text(snapshot.data.toString(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
