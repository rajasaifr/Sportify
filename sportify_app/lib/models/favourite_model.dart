/// Model for Favorite, based on the Analysis Class Diagram.
/// This represents a link between a user and a video content they favorited.
class Favorite {
  final String favoriteId;
  final String userId; // Links to UserModel
  final String contentId; // Links to VideoContent
  final String? category; // An optional, user-defined category
  final DateTime? addedAt;

  Favorite({
    required this.favoriteId,
    required this.userId,
    required this.contentId,
    this.category,
    this.addedAt,
  });

  /// Converts this Favorite instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'favoriteId': favoriteId,
      'userId': userId,
      'contentId': contentId,
      'category': category,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  /// Creates a Favorite instance from a JSON Map.
  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: json['favoriteId'],
      userId: json['userId'],
      contentId: json['contentId'],
      category: json['category'],
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : null,
    );
  }
}
