import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Handle typo: contenId -> contentId
    final contentId = json['contentId'] ?? json['contenId'];
    
    // Handle thumbnailUrl being a map (extract youtube value if it's a map)
    String thumbnailUrl;
    if (json['thumbnailUrl'] is Map) {
      final thumbMap = json['thumbnailUrl'] as Map;
      thumbnailUrl = thumbMap['youtube']?.toString() ?? 
                    'https://img.youtube.com/vi/$contentId/maxresdefault.jpg';
    } else {
      thumbnailUrl = json['thumbnailUrl']?.toString() ?? 
                     'https://img.youtube.com/vi/$contentId/maxresdefault.jpg';
    }
    
    // Handle videoUrls being a string (convert to map)
    Map<String, String> videoUrls;
    if (json['videoUrls'] is String) {
      final urlString = json['videoUrls'] as String;
      videoUrls = {'youtube': urlString.trim()};
    } else if (json['videoUrls'] is Map) {
      videoUrls = Map<String, String>.from(json['videoUrls']);
    } else {
      videoUrls = {};
    }
    
    return VideoContent(
      contentId: contentId ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
      uploadDate: json['uploadDate'] != null
          ? (json['uploadDate'] is Timestamp
              ? (json['uploadDate'] as Timestamp).toDate()
              : DateTime.parse(json['uploadDate'].toString()))
          : null,
      uploaderId: json['uploaderId'] ?? '',
      category: json['category'] ?? '',
      language: json['language'] ?? 'English',
      tags: List<String>.from(json['tags'] ?? []),
      teams: List<String>.from(json['teams'] ?? []),
      thumbnailUrl: thumbnailUrl,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      videoUrls: videoUrls,
      detailViews: json['detailViews'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
    );
  }
}
