import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'business_profile_page.dart'; 

class PostPage extends StatefulWidget {
  final QueryDocumentSnapshot post;

  const PostPage({super.key, required this.post});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final FirestoreService _firestoreService = FirestoreService();
  DocumentSnapshot? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBusinessProfile();
  }

  Future<void> _fetchBusinessProfile() async {
    try {
      final postData = widget.post.data() as Map<String, dynamic>;
      final String? businessId = postData['businessId'];
      
      if (businessId != null) {
        final profile = await _firestoreService.getUserProfile(businessId);
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.post.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'No Title';
    final String content = data['content'] ?? 'No Content';
    final Timestamp timestamp = data['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(timestamp.toDate());

    String businessName = '...';
    String? businessPhotoUrl;
    
    // Variable to hold the business ID for navigation
    String businessId = '';
    
    if (_businessProfile != null && _businessProfile!.exists) {
      final businessData = _businessProfile!.data() as Map<String, dynamic>;
      businessName = businessData['name'] ?? 'Unnamed Business';
      businessPhotoUrl = businessData['photoUrl'];
      
      // Get the business ID from the document snapshot
      businessId = _businessProfile!.id;
      
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Header
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_businessProfile != null)
              
              GestureDetector(
                onTap: () {
                  if (businessId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusinessProfilePage(businessId: businessId),
                      ),
                    );
                  }
                },
                // Use a transparent background to ensure the whole area is tappable
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: businessPhotoUrl != null ? NetworkImage(businessPhotoUrl) : null,
                          radius: 22,
                          child: businessPhotoUrl == null ? const Icon(Icons.store, size: 22) : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Posted on $formattedDate',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            
            const Divider(height: 24),

            // Post Content
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

