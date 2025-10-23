

class NotificationPreferences {
  final bool onNewPost;
  final bool onReviewResponse;
  final bool onNewReview;
  final bool onPostLike;
  final bool onNewFollower;
  final List<String> subscribedTags;
  final bool quietTimeEnabled;
  final String quietTimeStart;
  final String quietTimeEnd;

  NotificationPreferences({
    this.onNewPost = true,
    this.onReviewResponse = true,
    this.onNewReview = true,
    this.onPostLike = false,
    this.onNewFollower = true,
    this.subscribedTags = const [],
    this.quietTimeEnabled = false,
    this.quietTimeStart = "22:00",
    this.quietTimeEnd = "08:00",
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return NotificationPreferences(); 
    return NotificationPreferences(
      onNewPost: map['onNewPost'] ?? true,
      onReviewResponse: map['onReviewResponse'] ?? true,
      onNewReview: map['onNewReview'] ?? true,
      onPostLike: map['onPostLike'] ?? false,
      onNewFollower: map['onNewFollower'] ?? true,
      subscribedTags: List<String>.from(map['subscribedTags'] ?? []),
      quietTimeEnabled: map['quietTimeEnabled'] ?? false,
      quietTimeStart: map['quietTimeStart'] ?? "22:00",
      quietTimeEnd: map['quietTimeEnd'] ?? "08:00",
    );
  }
}