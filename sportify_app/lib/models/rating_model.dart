/// Model for Rating, based on the Analysis Class Diagram.
/// This represents a user's rating and review for a piece of content.
class Rating {
  final String ratingId;
  final String contentId; // Links to VideoContent
  final String userId; // Links to UserModel
  final int stars; // The star rating, e.g., 1-5
  final String? reviewText;
  final DateTime? createdAt;

  Rating({
    required this.ratingId,
    required this.contentId,
    required this.userId,
    required this.stars,
    this.reviewText,
    this.createdAt,
  });

  /// Converts this Rating instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'ratingId': ratingId,
      'contentId': contentId,
      'userId': userId,
      'stars': stars,
      'reviewText': reviewText,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Creates a Rating instance from a JSON Map.
  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      ratingId: json['ratingId'],
      contentId: json['contentId'],
      userId: json['userId'],
      stars: json['stars'],
      reviewText: json['reviewText'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
