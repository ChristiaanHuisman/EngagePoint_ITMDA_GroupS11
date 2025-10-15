// lib/models/post_model.dart

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

  PostModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.content,
    this.imageUrl,
    this.imageAspectRatio,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      title: data['title'] ?? 'No Title',
      content: data['content'] ?? 'No Content',
      imageUrl: data['imageUrl'],
      imageAspectRatio: data['imageAspectRatio'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Helper getter to handle date formatting cleanly
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt.toDate());
}