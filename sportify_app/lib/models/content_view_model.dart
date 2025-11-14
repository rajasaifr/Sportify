/// Model for ContentView, based on the Analysis Class Diagram.
/// This tracks a user's watch history for a specific piece of content.
class ContentView {
  final String contentViewId;
  final String userId; // Links to UserModel
  final String contentId; // Links to VideoContent
  final DateTime? viewedAt; // Last time they watched it
  final int percentCompleted;

  ContentView({
    required this.contentViewId,
    required this.userId,
    required this.contentId,
    this.viewedAt,
    this.percentCompleted = 0,
  });

  /// Converts this ContentView instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'contentViewId': contentViewId,
      'userId': userId,
      'contentId': contentId,
      'viewedAt': viewedAt?.toIso8601String(),
      'percentCompleted': percentCompleted,
    };
  }

  /// Creates a ContentView instance from a JSON Map.
  factory ContentView.fromJson(Map<String, dynamic> json) {
    return ContentView(
      contentViewId: json['contentViewId'],
      userId: json['userId'],
      contentId: json['contentId'],
      viewedAt: json['viewedAt'] != null
          ? DateTime.parse(json['viewedAt'])
          : null,
      percentCompleted: json['percentCompleted'] ?? 0,
    );
  }
}
