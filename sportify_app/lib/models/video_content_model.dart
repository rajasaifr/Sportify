/// Model for VideoContent, based on the Analysis Class Diagram.
class VideoContent {
  final String contentId;
  final String title;
  final String description;
  final int duration; // Duration in seconds
  final DateTime? uploadDate;
  final String uploaderId; // Links to UserModel or ContentManagerModel
  final String category;
  final String language;
  final List<String> tags;
  final List<String> teams;
  final String thumbnailUrl;
  final double averageRating;
  final Map<String, String> videoUrls; // {'1080p': 'url', '720p': 'url'}
  final int detailViews;
  final bool isFeatured;

  VideoContent({
    required this.contentId,
    required this.title,
    required this.description,
    required this.duration,
    this.uploadDate,
    required this.uploaderId,
    required this.category,
    required this.language,
    this.tags = const [],
    this.teams = const [],
    required this.thumbnailUrl,
    this.averageRating = 0.0,
    required this.videoUrls,
    this.detailViews = 0,
    this.isFeatured = false,
  });

  /// Converts this VideoContent instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'title': title,
      'description': description,
      'duration': duration,
      'uploadDate': uploadDate?.toIso8601String(),
      'uploaderId': uploaderId,
      'category': category,
      'language': language,
      'tags': tags,
      'teams': teams,
      'thumbnailUrl': thumbnailUrl,
      'averageRating': averageRating,
      'videoUrls': videoUrls,
      'detailViews': detailViews,
      'isFeatured': isFeatured,
    };
  }

  /// Creates a VideoContent instance from a JSON Map.
  factory VideoContent.fromJson(Map<String, dynamic> json) {
    return VideoContent(
      contentId: json['contentId'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'])
          : null,
      uploaderId: json['uploaderId'],
      category: json['category'],
      language: json['language'],
      tags: List<String>.from(json['tags'] ?? []),
      teams: List<String>.from(json['teams'] ?? []),
      thumbnailUrl: json['thumbnailUrl'],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      videoUrls: Map<String, String>.from(json['videoUrls'] ?? {}),
      detailViews: json['detailViews'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}
