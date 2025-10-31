import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostModel {
  final String id;
  final String businessId;
  final String title;
  final String content;
  final String? imageUrl;
  final double? imageAspectRatio;
  final Timestamp createdAt;
  final String status;
  final String? tag; 
  final int reactionCount;
  final String businessStatus;

  PostModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.content,
    this.imageUrl,
    this.imageAspectRatio,
    required this.createdAt,
    required this.status,
    this.tag, 
    this.reactionCount = 0,
    required this.businessStatus,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      imageAspectRatio: (data['imageAspectRatio'] as num?)?.toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'published',
      tag: data['tag'], 
      reactionCount: data['reactionCount'] ?? 0,
      businessStatus: data['businessStatus'] ?? 'pending',
    );
  }
  
  // Helper getter for formatted date
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt.toDate());

  
}