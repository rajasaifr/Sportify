import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
  }) async {
    Logger.info('Creating user profile for UID: $uid', tag: 'FirestoreService');

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('User profile created successfully', tag: 'FirestoreService');
    } on FirebaseException catch (e, stackTrace) {
      Logger.error('Firebase error while creating user profile', error: e, stackTrace: stackTrace, tag: 'FirestoreService');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while creating user profile', error: e, stackTrace: stackTrace, tag: 'FirestoreService');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    Logger.info('Getting user profile for UID: $uid', tag: 'FirestoreService');

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Logger.info('User profile retrieved successfully', tag: 'FirestoreService');
        return doc.data() as Map<String, dynamic>;
      } else {
        Logger.warning('User profile not found for UID: $uid', tag: 'FirestoreService');
        return null;
      }
    } on FirebaseException catch (e, stackTrace) {
      Logger.error('Firebase error while getting user profile', error: e, stackTrace: stackTrace, tag: 'FirestoreService');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while getting user profile', error: e, stackTrace: stackTrace, tag: 'FirestoreService');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    Logger.info('Updating user profile for UID: $uid', tag: 'FirestoreService');

    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.info('User profile updated successfully', tag: 'FirestoreService');
    } on FirebaseException catch (e, stackTrace) {
      Logger.error('Firebase error while updating user profile', error: e, stackTrace: stackTrace, tag: 'FirestoreService');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while updating user profile', error: e, stackTrace: stackTrace, tag: 'FirestoreService');
      rethrow;
    }
  }
}