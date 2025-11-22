// services/profile_service.dart
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/interfaces/profile_service_interface.dart';
import 'package:sportify_app/repositories/user_repository.dart';

/// Profile Service Implementation
/// Applies Single Responsibility Principle (SRP) - handles only profile operations
/// Implements IProfileService interface - Dependency Inversion Principle (DIP)
class ProfileService implements IProfileService {
  final UserRepository _userRepository;

  /// Constructor with dependency injection
  /// Applies Dependency Inversion Principle (DIP)
  ProfileService({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  /// Updates user profile information in Firestore
  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _userRepository.updateUser(user);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Gets user profile by UID
  @override
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      return await _userRepository.getUserById(uid);
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Gets real-time stream of user profile
  @override
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _userRepository.getUserStream(uid);
  }

  /// Updates specific profile fields
  @override
  Future<void> updateProfileFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _userRepository.updateUserFields(uid: uid, fields: fields);
    } catch (e) {
      throw Exception('Failed to update profile fields: $e');
    }
  }
}