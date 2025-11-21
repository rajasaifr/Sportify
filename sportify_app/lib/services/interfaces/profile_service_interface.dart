import 'package:sportify_app/models/user_model.dart';

/// Interface for profile service
/// Applies Dependency Inversion Principle (DIP) - depend on abstractions
abstract class IProfileService {
  /// Updates user profile information in Firestore
  Future<void> updateUserProfile(UserModel user);

  /// Gets user profile by UID
  Future<UserModel?> getUserProfile(String uid);

  /// Gets real-time stream of user profile
  Stream<UserModel?> getUserProfileStream(String uid);

  /// Updates specific profile fields
  Future<void> updateProfileFields({
    required String uid,
    required Map<String, dynamic> fields,
  });
}

