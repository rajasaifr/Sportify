// services/profile_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates user profile information in Firestore
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Gets user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  /// Gets real-time stream of user profile
  Stream<UserModel?> getUserProfileStream(String uid) {
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

  /// Updates specific profile fields
  Future<void> updateProfileFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(fields);
    } catch (e) {
      throw Exception('Failed to update profile fields: $e');
    }
  }
}