import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/models/friendship_model.dart';
import 'package:sportify_app/utils/logger.dart';
import 'package:sportify_app/theme/app_theme.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      appBar: AppBar(
        backgroundColor: AppTheme.bgStart,
        elevation: 0,
        title: const Text(
          'Add Friends',
          style: TextStyle(color: AppTheme.textMain),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textMain),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Search Results or Empty State
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Users',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMain.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textMain),
            decoration: InputDecoration(
              hintText: 'Search by username...',
              hintStyle: TextStyle(color: AppTheme.textFaint.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textFaint),
              filled: true,
              fillColor: AppTheme.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: _performSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'Search for users by their display name',
            style: TextStyle(color: AppTheme.textFaint.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    final initial = (user.displayName ?? user.email.split('@')[0])[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.displayName ?? 'No name',
          style: const TextStyle(color: AppTheme.textMain),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: AppTheme.textFaint.withValues(alpha: 0.7)),
        ),
        trailing: _buildAddButton(user, _getCurrentUserId()),
      ),
    );
  }
Widget _buildAddButton(UserModel user, String currentUserId) {
  return FutureBuilder<FriendshipStatus?>(
    future: Provider.of<FirestoreService>(context, listen: false)
        .getFriendshipStatus(currentUserId, user.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      }
      
      final status = snapshot.data;
      
      return _getFriendButtonByStatus(status, user);
    },
  );
}

Widget _getFriendButtonByStatus(FriendshipStatus? status, UserModel user) {
  switch (status) {
    case FriendshipStatus.pending:
      // Check who sent the request
      return FutureBuilder<Friendship?>(
        future: _getFriendshipBetweenUsers(user.uid),
        builder: (context, friendshipSnapshot) {
          if (friendshipSnapshot.connectionState == ConnectionState.waiting) {
            return const OutlinedButton(
              onPressed: null,
              child: Text('Loading...'),
            );
          }
          
          final friendship = friendshipSnapshot.data;
          final isRequestSentByMe = friendship?.user1Id == _getCurrentUserId();
          
          if (isRequestSentByMe) {
            return const OutlinedButton(
              onPressed: null,
              child: Text('Request Sent'),
            );
          } else {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptFriendRequest(friendship!.friendshipId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _declineFriendRequest(friendship!.friendshipId),
                  child: const Text('Decline'),
                ),
              ],
            );
          }
        },
      );
      
    case FriendshipStatus.accepted:
      return const OutlinedButton(
        onPressed: null,
        child: Text('Friends'),
      );
      
    case FriendshipStatus.declined:
      return ElevatedButton(
        onPressed: () => _sendFriendRequest(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text('Add Friend'),
      );
    case null:
    default:
      return ElevatedButton(
        onPressed: () => _sendFriendRequest(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text('Add Friend'),
      );
  }
}

  void _performSearch(String query) async {
    if (query.length < 2) { // Don't search for very short queries
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await Provider.of<FirestoreService>(context, listen: false)
          .searchUsers(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      Logger.error("Search error", error: e, tag: 'AddFriendScreen');
    }
  }

  void _sendFriendRequest(UserModel targetUser) async {
  final authService = Provider.of<AuthService>(context, listen: false);
  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
  final currentUser = authService.currentUser;

  if (currentUser == null) return;

  // Prevent sending to yourself
  if (currentUser.uid == targetUser.uid) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot send a friend request to yourself')),
    );
    return;
  }

  try {
    // Check if friendship already exists
    final existingFriendship = await firestoreService.getFriendshipBetweenUsers(
      currentUser.uid, 
      targetUser.uid
    );

    if (!mounted) return;
    if (existingFriendship != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request already ${existingFriendship.status.name}')),
      );
      return;
    }

    // Send new request
    await firestoreService.sendFriendRequest(
      fromUserId: currentUser.uid,
      toUserId: targetUser.uid,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to ${targetUser.displayName}')),
    );
    
    // Refresh the UI to update button state
    setState(() {});
    
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send request: $e')),
    );
  }
}
  void _acceptFriendRequest(String friendshipId) async {
  try {
    await Provider.of<FirestoreService>(context, listen: false)
        .acceptFriendRequest(friendshipId);
    if (!mounted) return;
    setState(() {}); // Refresh UI
  } catch (e) {
    // Handle error
  }
}

void _declineFriendRequest(String friendshipId) async {
  try {
    // Instead of updating status to declined, DELETE the friendship
    await Provider.of<FirestoreService>(context, listen: false)
        .deleteFriendship(friendshipId);
    if (!mounted) return;
    setState(() {}); // Refresh UI
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to decline request: $e')),
    );
  }
}

  
  String _getCurrentUserId() {
  return Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
}

Future<Friendship?> _getFriendshipBetweenUsers(String otherUserId) async {
  final currentUserId = _getCurrentUserId();
  return Provider.of<FirestoreService>(context, listen: false)
      .getFriendshipBetweenUsers(currentUserId, otherUserId);
}
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}