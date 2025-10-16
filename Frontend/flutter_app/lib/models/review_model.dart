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

    Timestamp parseTimestamp(dynamic value) {
      if (value == null) return Timestamp.now();
      if (value is Timestamp) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        return Timestamp.fromDate(parsed ?? DateTime.now());
      }
      return Timestamp.now();
    }

    return ReviewModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      customerId: data['customerId'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt: parseTimestamp(data['createdAt']),
      response: data['response'],
      respondedAt: parseTimestamp(data['respondedAt']),
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
