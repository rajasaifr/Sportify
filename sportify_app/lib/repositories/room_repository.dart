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
      final roomDoc = _firestore.collection('rooms').doc();
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

  /// Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (doc.exists) {
        return Room.fromJson(doc.data() as Map<String, dynamic>);
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
}

