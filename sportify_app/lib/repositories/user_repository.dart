import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/user_model.dart';

/// Repository pattern for user data access
/// Applies Single Responsibility Principle (SRP) - handles only user data operations
/// Applies Abstraction - abstracts data access details
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user by UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Get user stream (real-time updates)
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Create user document
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user document
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Update specific user fields
  Future<void> updateUserFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(fields);
    } catch (e) {
      throw Exception('Failed to update user fields: $e');
    }
  }

  /// Search users by display name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore.collection('users').get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) {
            final displayName = user.displayName?.toLowerCase() ?? '';
            final email = user.email.toLowerCase();
            final searchQuery = query.toLowerCase();
            return displayName.contains(searchQuery) || email.contains(searchQuery);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}

