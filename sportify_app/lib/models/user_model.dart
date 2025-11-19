enum UserRole { user, contentManager, admin }

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final UserRole role;
  final String? bio;
  final String? profilePicUrl;
  final List<String>? favoriteTeams;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.createdAt,
    this.role = UserRole.user,
    this.bio,
    this.profilePicUrl,
    this.favoriteTeams,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt?.toIso8601String(),
      'role': role.name,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'favoriteTeams': favoriteTeams ?? [],
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.user,
      ),
      bio: json['bio'],
      profilePicUrl: json['profilePicUrl'],
      favoriteTeams: json['favoriteTeams'] != null
          ? List<String>.from(json['favoriteTeams'])
          : [],
    );
  }
}
