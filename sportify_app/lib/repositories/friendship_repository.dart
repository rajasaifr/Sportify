import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/friendship_model.dart';

/// Repository pattern for friendship data access
/// Applies Single Responsibility Principle (SRP) - handles only friendship data operations
/// Applies Abstraction - abstracts data access details
class FriendshipRepository {
  final FirebaseFirestore _firestore;

  FriendshipRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a friendship request
  Future<void> createFriendship(Friendship friendship) async {
    try {
      await _firestore
          .collection('friendships')
          .doc(friendship.friendshipId)
          .set(friendship.toJson());
    } catch (e) {
      throw Exception('Failed to create friendship: $e');
    }
  }

  /// Get friendships for a user
  Stream<List<Friendship>> getFriendshipsForUser(String userId) {
    return _firestore
        .collection('friendships')
        .where('status', isEqualTo: FriendshipStatus.accepted.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Friendship.fromJson(doc.data()))
          .where((friendship) =>
              friendship.user1Id == userId || friendship.user2Id == userId)
          .toList();
    });
  }

  /// Get pending requests received by a user
  Stream<List<Friendship>> getPendingRequestsReceived(String userId) {
    return _firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.pending.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Friendship.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get friendship between two users
  Future<Friendship?> getFriendshipBetweenUsers(String user1Id, String user2Id) async {
    try {
      // Check combination 1: user1Id -> user2Id
      final snapshot1 = await _firestore
          .collection('friendships')
          .where('user1Id', isEqualTo: user1Id)
          .where('user2Id', isEqualTo: user2Id)
          .limit(1)
          .get();

      if (snapshot1.docs.isNotEmpty) {
        return Friendship.fromJson(snapshot1.docs.first.data());
      }

      // Check combination 2: user2Id -> user1Id
      final snapshot2 = await _firestore
          .collection('friendships')
          .where('user1Id', isEqualTo: user2Id)
          .where('user2Id', isEqualTo: user1Id)
          .limit(1)
          .get();

      if (snapshot2.docs.isNotEmpty) {
        return Friendship.fromJson(snapshot2.docs.first.data());
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get friendship: $e');
    }
  }

  /// Update friendship status
  Future<void> updateFriendshipStatus(String friendshipId, FriendshipStatus status) async {
    try {
      await _firestore.collection('friendships').doc(friendshipId).update({
        'status': status.name,
      });
    } catch (e) {
      throw Exception('Failed to update friendship: $e');
    }
  }

  /// Delete friendship
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      await _firestore.collection('friendships').doc(friendshipId).delete();
    } catch (e) {
      throw Exception('Failed to delete friendship: $e');
    }
  }
}

