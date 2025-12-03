import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/models/sport_model.dart';
import 'package:sportify_app/models/team_model.dart';
import 'package:sportify_app/models/room_model.dart';
import 'package:sportify_app/models/video_content_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/profile_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
import 'package:sportify_app/screens/rooms_screen.dart';
import 'package:sportify_app/screens/profile_screen.dart';
import 'package:sportify_app/screens/friends_screen.dart';
import 'package:sportify_app/screens/room_screen.dart';
import 'package:sportify_app/theme/app_theme.dart';
import 'package:sportify_app/widgets/neon_button.dart';
import 'dart:ui'; // Add this import for ImageFilter

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Expose tab controller for external access (used by RoomScreen)
  TabController get tabController => _tabController;

  bool _isSidebarOpen = true; // Sidebar state
  final ScrollController _scrollController =
      ScrollController(); // To preserve scroll position

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _goToLobby() {
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black, // Pure black background
        ),
        child: Stack(
          children: [
            // MAIN CONTENT (No floating particles)
            Column(
              children: [
                // Merged AppBar with Tabs, Logo, and Profile in one line
                _buildMergedNavBar(context),
                // Content Area
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLobbyView(context),
                      const RoomsScreen(),
                      const FriendsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergedNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgStart.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sportify Text (matching login page style)
          GestureDetector(
            onTap: _goToLobby,
            child: const Text(
              'SPORTIFY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Tabs in the middle
          Expanded(
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primary,
                    width: 3,
                  ),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textFaint,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "LOBBY"),
                Tab(text: "ROOMS"), // Changed from "ROOM" to "ROOMS"
                Tab(text: "FRIENDS"),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Profile Button
          _buildProfileButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final currentUser = authService.currentUser;

    return StreamBuilder<UserModel?>(
      stream: currentUser != null
          ? profileService.getUserProfileStream(currentUser.uid)
          : Stream.value(null),
      builder: (context, snapshot) {
        final userModel = snapshot.data;
        final displayName = userModel?.displayName ??
            currentUser?.displayName ??
            currentUser?.email?.split('@')[0] ??
            'U';
        final profilePicUrl = userModel?.profilePicUrl ?? currentUser?.photoURL;
        final initial =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          color: AppTheme.inputFill,
          elevation: 8,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
              image: profilePicUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profilePicUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: profilePicUrl == null ? AppTheme.primary : null,
            ),
            child: profilePicUrl == null
                ? Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  )
                : null,
          ),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'manage',
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppTheme.primary, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Manage account',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Sign out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            if (value == 'manage') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            } else if (value == 'signout') {
              _showSignOutDialog(context);
            }
          },
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: AppTheme.textMain),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: AppTheme.textFaint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textFaint),
              ),
            ),
            NeonButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                authService.signOut();
              },
              backgroundColor: Colors.redAccent,
              glowColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Sign Out',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLobbyView(BuildContext context) {
    return Row(
      children: [
        // Left Sidebar - Favorite Teams (Collapsible)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isSidebarOpen ? 250 : 0,
          clipBehavior: Clip.hardEdge, // Prevent overflow during animation
          color: AppTheme
              .bgStart, // Maintain background during animation to prevent black flash
          child: _isSidebarOpen
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // Only show content if width is sufficient (above 150px to prevent overflow)
                    if (constraints.maxWidth < 150) {
                      return const SizedBox.shrink();
                    }
                    return _buildFavoriteTeamsSidebar(context);
                  },
                )
              : const SizedBox.shrink(),
        ),
        // Main Content Area
        Expanded(
          child: _buildMainContentArea(context),
        ),
      ],
    );
  }

  Widget _buildFavoriteTeamsSidebar(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final currentUser = authService.currentUser;

    return Container(
      width: 250, // Fixed width to prevent overflow
      decoration: BoxDecoration(
        color: AppTheme.bgStart,
        border: Border(
          right: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header with Close Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Favorite Teams',
                    style: TextStyle(
                      color: AppTheme.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppTheme.textFaint,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  onPressed: () {
                    // Preserve scroll position before closing sidebar
                    final currentScrollPosition = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    setState(() {
                      _isSidebarOpen = false;
                    });
                    // Restore scroll position after rebuild
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(currentScrollPosition);
                      }
                    });
                  },
                  tooltip: 'Hide sidebar',
                ),
              ],
            ),
          ),
          // Sidebar Content - Scrollable
          Expanded(
            child: currentUser == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Please sign in',
                        style: TextStyle(
                          color: AppTheme.textFaint.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : StreamBuilder<UserModel?>(
                    stream:
                        profileService.getUserProfileStream(currentUser.uid),
                    builder: (context, userSnapshot) {
                      final userModel = userSnapshot.data;
                      final favoriteTeams = userModel?.favoriteTeams ?? [];

                      if (favoriteTeams.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 48,
                                  color:
                                      AppTheme.textFaint.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No favorite teams yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textFaint
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add teams in your profile',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textFaint
                                        .withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics:
                            const BouncingScrollPhysics(), // Enable smooth vertical scrolling
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: favoriteTeams.length,
                        itemBuilder: (context, index) {
                          final teamName = favoriteTeams[index];
                          return FutureBuilder<Team?>(
                            future: Provider.of<FirestoreService>(context, listen: false)
                                .getTeamByName(teamName),
                            builder: (context, snapshot) {
                              final team = snapshot.data;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.inputFill,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: team?.logoUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Image.network(
                                            team!.logoUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primary
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.sports,
                                                  color: AppTheme.primary,
                                                  size: 20,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Icon(
                                            Icons.sports,
                                            color: AppTheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                  title: Text(
                                    team?.name ?? teamName,
                                    style: const TextStyle(
                                      color: AppTheme.textMain,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: team?.sport != null
                                      ? Text(
                                          _normalizeSportName(team!.sport!),
                                          style: TextStyle(
                                            color: AppTheme.textFaint
                                                .withValues(alpha: 0.6),
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentArea(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Stack(
      children: [
        // Main Content
        SingleChildScrollView(
          controller: _scrollController, // Preserve scroll position
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show Sidebar Button (when closed) - positioned at top
              if (!_isSidebarOpen)
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.primary,
                        ),
                      ),
                      onPressed: () {
                        // Preserve scroll position before opening sidebar
                        final currentScrollPosition =
                            _scrollController.hasClients
                                ? _scrollController.offset
                                : 0.0;
                        setState(() {
                          _isSidebarOpen = true;
                        });
                        // Restore scroll position after rebuild
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(currentScrollPosition);
                          }
                        });
                      },
                      tooltip: 'Show favorite teams',
                    ),
                  ),
                ),
              // Featured Room Banner (Netflix-style)
              _buildFeaturedBanner(context, firestoreService),

              const SizedBox(height: 24),

              // Sports Sections (Horizontal Scrolling Rows)
              FutureBuilder<List<Sport>>(
                future: Provider.of<FirestoreService>(context, listen: false)
                    .getSports(limit: 5),
                builder: (context, sportsSnapshot) {
                  if (sportsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  }

                  if (sportsSnapshot.hasError || !sportsSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final sports = sportsSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sports.map((sport) {
                      return _buildSportRow(context, sport);
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBanner(
      BuildContext context, FirestoreService firestoreService) {
    return StreamBuilder<List<Room>>(
      stream: firestoreService.getPublicRoomsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildHeroBanner(context, null, []),
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ],
          );
        }

        // Get top 4-5 rooms sorted by participant count
        final rooms = snapshot.hasData
            ? snapshot.data!
                .where((room) => room.roomType == RoomType.public)
                .toList()
            : <Room>[];
        rooms.sort((a, b) => b.participants.length.compareTo(a.participants.length));
        final topRooms = rooms.take(5).toList();

        return _buildHeroBanner(context, topRooms.length, topRooms, firestoreService);
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, int? roomCount, List<Room> topRooms, [FirestoreService? firestoreService]) {
    return Container(
      height: 600, // Increased height to cover cards
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1637421894898-13740d20a36e?w=1200&auto=format&fit=crop&q=80&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDI3fHx8ZW58MHx8fHx8',
          ),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Stack(
          children: [
            // Text Overlay on Left
            Positioned(
              left: 40,
              bottom: 220, // Adjusted position to be above cards
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Front row seats for every\nGame Night',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 500,
                    child: Text(
                      'Join the most active rooms and watch live sports with fans from around the world. Experience real-time reactions, discussions, and the thrill of the game together.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // See More Button on Right
            Positioned(
              right: 40,
              bottom: 260, // Adjusted position
              child: TextButton(
                onPressed: () {
                  // Navigate to rooms screen or scroll to rooms section
                  _tabController.animateTo(1); // Navigate to Rooms tab
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'See more',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Event Cards Overlay at Bottom
            if (firestoreService != null && topRooms.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: topRooms.length,
                    itemBuilder: (context, index) {
                      final room = topRooms[index];
                      return _buildTopRoomCard(context, room, firestoreService);
                    },
                  ),
                ),
              )
            else if (topRooms.isEmpty && firestoreService != null)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'No rooms available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRoomCard(
      BuildContext context, Room room, FirestoreService firestoreService) {
    return FutureBuilder<VideoContent?>(
      future: firestoreService.getVideoById(room.contentId),
      builder: (context, videoSnapshot) {
        final video = videoSnapshot.data;
        final thumbnailUrl = video?.thumbnailUrl;
        
        // Format room creation time or use current time
        final now = DateTime.now();
        final roomTime = room.createdAt ?? now;
        final timeLabel = _formatRoomTime(roomTime);

        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16), // Match container border radius
            child: Stack(
              children: [
                // Thumbnail background
                if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.bgStart,
                        );
                      },
                    ),
                  )
                else
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.bgStart,
                            AppTheme.primary.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time/Date Label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20), // Pill shape
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeLabel,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (room.roomType == RoomType.private) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.lock,
                                  size: 14,
                                  color: Colors.black,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Room Title
                        Text(
                          room.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (room.team1Name != null && room.team2Name != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${room.team1Name} vs ${room.team2Name}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Participants count
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${room.participants.length} watching',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Join Now Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _navigateToRoomWithVerification(context, room);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), // Rounded button
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'JOIN NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRoomTime(DateTime roomTime) {
    final now = DateTime.now();
    final difference = now.difference(roomTime);

    if (difference.inDays == 0) {
      // Today
      final hour = roomTime.hour.toString().padLeft(2, '0');
      final minute = roomTime.minute.toString().padLeft(2, '0');
      return 'TODAY $hour:$minute';
    } else if (difference.inDays == 1) {
      return 'YESTERDAY';
    } else if (difference.inDays < 7) {
      final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      return '${weekdays[roomTime.weekday - 1]} ${roomTime.day} ${roomTime.month.toString().padLeft(2, '0')}';
    } else {
      return '${roomTime.day} ${_getMonthAbbr(roomTime.month)} ${roomTime.hour.toString().padLeft(2, '0')}:${roomTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  // Helper method to get sport-specific background image
  String _getSportBackgroundImage(String sportName) {
    final sportLower = sportName.toLowerCase();
    if (sportLower.contains('rugby')) {
      return 'https://images.unsplash.com/photo-1495329144860-da404d597791?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    } else if (sportLower.contains('football') || sportLower.contains('soccer')) {
      return 'https://images.unsplash.com/photo-1676746424139-77f8bd8922a8?q=80&w=436&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    } else if (sportLower.contains('basketball')) {
      return 'https://images.unsplash.com/photo-1533923156502-be31530547c4?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    } else if (sportLower.contains('cricket')) {
      return 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=1005&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    } else if (sportLower.contains('f1') || sportLower.contains('formula')) {
      return 'https://images.unsplash.com/photo-1742744652734-d5ec6598b5da?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    }
    // Default image (the original one)
    return 'https://images.unsplash.com/photo-1637421894898-13740d20a36e?w=1200&auto=format&fit=crop&q=80&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1yZWxhdGVkfDI3fHx8ZW58MHx8fHx8';
  }

  Widget _buildSportRow(BuildContext context, Sport sport) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Banner for Sport with Teams Overlay
        _buildSportHeroBanner(context, sport),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSportHeroBanner(BuildContext context, Sport sport) {
    return Container(
      height: 600,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_getSportBackgroundImage(sport.name)),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Stack(
          children: [
            // Text Overlay on Top Left
            Positioned(
              left: 40,
              top: 40, // Changed from bottom to top
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${sport.name} on SPORTIFY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 500,
                    child: Text(
                      'Watch live ${sport.name.toLowerCase()} matches, highlights, and join active rooms with fans from around the world.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Team Cards Overlay at Bottom - Fit horizontally
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FutureBuilder<List<Team>>(
                future: Provider.of<FirestoreService>(context, listen: false)
                    .getTeamsBySport(sport.name, limit: 6), // Limit to 5-6 teams
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final teams = snapshot.data!;
                  // Calculate card width to fit all cards horizontally
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth - 32; // Account for padding
                      final cardWidth = (availableWidth / teams.length) - 12; // Divide by team count, subtract margin
                      
                      return SizedBox(
                        height: 200,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: teams.map((team) {
                            return Container(
                              width: cardWidth,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: _buildTeamCard(context, team),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Team team) {
    // Make cards more rectangular - wider when sidebar is closed
    // Use AnimatedContainer to smoothly transition card width
    const cardHeight = 180.0; // Fixed height for rectangular shape
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isSidebarOpen ? 160.0 : 200.0,
      height: cardHeight,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          _showTeamOptionsMenu(context, team);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16), // Rounded corners
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3), // Semi-transparent black
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), // Subtle border
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8), // Dark shadow
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display team logo if available, otherwise show placeholder
                  if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        team.logoUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.sports,
                              color: AppTheme.primary,
                              size: 35,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports,
                        color: AppTheme.primary,
                        size: 35,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      team.name,
                      style: const TextStyle(
                        color: AppTheme.textMain,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (team.country != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      team.country!,
                      style: const TextStyle(
                        color: AppTheme.textFaint,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows team options menu when a team card is clicked
  void _showTeamOptionsMenu(BuildContext context, Team team) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Team name header with close button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(
                            color: AppTheme.textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textFaint,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Options
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Find rooms for this team',
                      style: TextStyle(
                        color: AppTheme.textMain,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textFaint,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(); // Close the dialog
                      // Navigate to Rooms tab with team filter
                      _tabController.animateTo(1); // Switch to Rooms tab (index 1)
                      // Navigate to RoomsScreen with team filter
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RoomsScreen(filterByTeam: team.name),
                          ),
                        );
                      });
                    },
                  ),
                ),
                // Add more options here later
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 5),
                //   child: ListTile(
                //     leading: Container(
                //       padding: const EdgeInsets.all(8),
                //       decoration: BoxDecoration(
                //         color: AppTheme.primary.withValues(alpha: 0.2),
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //       child: const Icon(
                //         Icons.favorite,
                //         color: AppTheme.primary,
                //         size: 20,
                //       ),
                //     ),
                //     title: const Text(
                //       'Add to favorites',
                //       style: TextStyle(
                //         color: AppTheme.textMain,
                //         fontWeight: FontWeight.w500,
                //         fontSize: 16,
                //       ),
                //     ),
                //     trailing: const Icon(
                //       Icons.arrow_forward_ios,
                //       color: AppTheme.textFaint,
                //       size: 16,
                //     ),
                //     onTap: () {
                //       // Add favorite functionality
                //       Navigator.of(context).pop();
                //     },
                //   ),
                // ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a dialog to enter room code for private rooms
  Future<bool> _showRoomCodeDialog(BuildContext context, Room room) async {
    final codeController = TextEditingController();
    bool? result = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          title: const Text(
            'Private Room',
            style: TextStyle(color: AppTheme.textMain, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This room requires an access code.',
                style: TextStyle(color: AppTheme.textFaint),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                style: const TextStyle(color: AppTheme.textMain),
                decoration: InputDecoration(
                  labelText: 'Enter Room Code',
                  labelStyle: const TextStyle(color: AppTheme.textFaint),
                  hintText: 'e.g., Cr23AB',
                  hintStyle: TextStyle(color: AppTheme.textFaint.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: AppTheme.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                result = false;
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textFaint),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredCode = codeController.text.trim().toUpperCase();
                if (enteredCode == room.roomCode?.toUpperCase()) {
                  Navigator.of(dialogContext).pop();
                  result = true;
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid room code. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Navigates to room screen with code verification for private rooms
  Future<void> _navigateToRoomWithVerification(BuildContext context, Room room) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    
    // If user is the host, allow direct access
    if (currentUserId == room.hostId) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomScreen(room: room),
        ),
      );
      return;
    }
    
    // If room is private, ask for code
    if (room.roomType == RoomType.private) {
      final hasAccess = await _showRoomCodeDialog(context, room);
      if (!mounted) return;
      if (hasAccess) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RoomScreen(room: room),
          ),
        );
      }
    } else {
      // Public room, allow direct access
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomScreen(room: room),
        ),
      );
    }
  }

  /// Normalize sport names for consistent display
  /// Converts API names (like "Soccer") to display names (like "Football")
  String _normalizeSportName(String sportName) {
    switch (sportName.toLowerCase()) {
      case 'soccer':
        return 'Football';
      case 'motorsport':
        return 'F1';
      case 'football':
      case 'cricket':
      case 'basketball':
      case 'f1':
      case 'rugby':
        // Capitalize first letter
        return sportName[0].toUpperCase() +
            sportName.substring(1).toLowerCase();
      default:
        return sportName;
    }
  }
}
