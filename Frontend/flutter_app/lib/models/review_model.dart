
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String businessId;
  final String customerId;
  final double rating;
  final String comment;
  final Timestamp createdAt;
  final String? response;
  final Timestamp? respondedAt; 

  ReviewModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.response,
    this.respondedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      customerId: data['customerId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      response: data['response'],
      respondedAt: data['respondedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'customerId': customerId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'response': response,
      'respondedAt': respondedAt,
    };
  }
}