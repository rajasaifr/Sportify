import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify_app/models/room_model.dart';

/// Repository pattern for room data access
/// Applies Single Responsibility Principle (SRP) - handles only room data operations
/// Applies Abstraction - abstracts data access details
class RoomRepository {
  final FirebaseFirestore _firestore;

  RoomRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new room
  Future<String?> createRoom(Room room) async {
    try {
      // Use the roomId from the Room object if provided, otherwise generate a new one
      final roomDoc = room.roomId.isNotEmpty
          ? _firestore.collection('rooms').doc(room.roomId)
          : _firestore.collection('rooms').doc();
      await roomDoc.set(room.toJson());
      return roomDoc.id;
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  /// Get public rooms stream
  Stream<List<Room>> getPublicRoomsStream() {
    return _firestore
        .collection('rooms')
        .where('roomType', isEqualTo: RoomType.public.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Room.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get all rooms stream (public and private)
  Stream<List<Room>> getAllRoomsStream() {
    return _firestore
        .collection('rooms')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['roomId'] = data['roomId'] ?? doc.id;
            return Room.fromJson(data);
          })
          .toList();
    });
  }

  /// Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure roomId is set (use document ID if not in data)
        data['roomId'] = data['roomId'] ?? doc.id;
        return Room.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  /// Update room
  Future<void> updateRoom(Room room) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(room.roomId)
          .set(room.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  /// Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      // Delete the room document and all its subcollections (messages)
      final batch = _firestore.batch();
      
      // Delete all messages in the room
      final messagesSnapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('messages')
          .get();
      
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the room document
      batch.delete(_firestore.collection('rooms').doc(roomId));
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }
}

