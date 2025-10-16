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

  final List<bool> _isSelected = [true, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _businessId == null
          ? const Center(child: Text("Error: Not logged in."))
          : Column(
              children: [
                Container(
                  width: double.infinity,
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
                      constraints: const BoxConstraints(minHeight: 38.0, minWidth: 120.0),
                      selectedColor: Colors.white,
                      fillColor: Theme.of(context).colorScheme.primary,
                      color: Theme.of(context).colorScheme.primary,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Engagement')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Sentiment')),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _isSelected[0] ? _buildEngagementView() : _buildSentimentView(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEngagementView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        const SizedBox(height: 24),
        Text(
          'Engagement Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
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
    );
  }

  Widget _buildSentimentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Sentiment Analysis',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          icon: Icons.thumb_up,
          label: 'Positive Reviews',
          future: Future.value(0), 
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.thumb_down,
          label: 'Negative Reviews',
          future: Future.value(0), 
          color: Colors.red,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          icon: Icons.remove,
          label: 'Neutral Reviews',
          future: Future.value(0), 
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Color color,
    Stream<int>? stream,
    Future<int>? future,
  }) {
    // ... (This helper method remains unchanged) ...
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
                      return Text(
                        snapshot.data.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  )
                else if (future != null)
                  FutureBuilder<int>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('...');
                      }
                      return Text(
                        snapshot.data.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      );
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
