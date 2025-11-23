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
import 'package:sportify_app/screens/create_room_screen.dart';
import 'package:sportify_app/screens/profile_screen.dart';
import 'package:sportify_app/screens/friends_screen.dart';
import 'package:sportify_app/screens/room_screen.dart';
import 'package:sportify_app/theme/app_theme.dart';
import 'package:sportify_app/widgets/neon_button.dart';
import 'package:sportify_app/widgets/floating_emitter.dart';

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
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 1. FLOATING EMITTER (Background Layer)
            const Positioned.fill(
              child: FloatingEmitter(
                // --- JPG ASSET PATHS ---
                assetPaths: [
                  'assets/images/floating_icons/basketball.jpg',
                  'assets/images/floating_icons/bat.jpg',
                  'assets/images/floating_icons/glove.jpg',
                  'assets/images/floating_icons/helmet.jpg',
                  'assets/images/floating_icons/racket.jpg',
                  'assets/images/floating_icons/soccer_ball.jpg',
                ],
                emissionInterval: Duration(milliseconds: 500),
                particleDuration: Duration(seconds: 20),
                particleSizeMin: 25.0, // Smaller icons
                particleSizeMax: 45.0, // Smaller icons
                maxParticles: 16, // Slightly increased
              ),
            ),
            // 2. MAIN CONTENT (Foreground Layer)
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
                      const CreateRoomScreen(),
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
          // Sportify Logo with Neon Glow
          GestureDetector(
            onTap: _goToLobby,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/App_Icon.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, AppTheme.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: const Text(
                    'SPORTIFY',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
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
                Tab(text: "ROOM"),
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
                Expanded(
                  child: Text(
                    'Favorite Teams',
                    style: const TextStyle(
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 400,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A2E), // Dark purple (opaque)
                  AppTheme.bgStart,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_esports,
                    size: 64,
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Featured Rooms',
                    style: TextStyle(
                      color: AppTheme.textFaint,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final featuredRoom = snapshot.data!.first;
        return FutureBuilder<VideoContent?>(
          future: firestoreService.getVideoById(featuredRoom.contentId),
          builder: (context, videoSnapshot) {
            final video = videoSnapshot.data;
            final thumbnailUrl = video?.thumbnailUrl;

            return Container(
              width: double.infinity,
              height: 400,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video Thumbnail Background
                    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to gradient if image fails to load
                            return Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1A0A2E),
                                    AppTheme.bgStart,
                                    AppTheme.bgEnd,
                                  ],
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            // Show gradient while loading
                            return Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1A0A2E),
                                    AppTheme.bgStart,
                                    AppTheme.bgEnd,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      // Fallback gradient if no thumbnail
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A0A2E),
                                AppTheme.bgStart,
                                AppTheme.bgEnd,
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Gradient Overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                    // Content Overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            featuredRoom.name,
                            style: const TextStyle(
                              color: AppTheme.textMain,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (featuredRoom.description != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              featuredRoom.description!,
                              style: const TextStyle(
                                color: AppTheme.textFaint,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 20),
                          NeonButton(
                            onPressed: () {
                              _navigateToRoomWithVerification(context, featuredRoom);
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'JOIN ROOM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSportRow(BuildContext context, Sport sport) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                _getSportIcon(sport.name),
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                sport.name.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.textMain,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Team>>(
          future: Provider.of<FirestoreService>(context, listen: false)
              .getTeamsBySport(sport.name, limit: 10),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final teams = snapshot.data!;

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics:
                    const BouncingScrollPhysics(), // Smooth horizontal scrolling
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return _buildTeamCard(context, team);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
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
      child: NeonButton(
        onPressed: () {
          // Navigate to team details or create room with team
        },
        isOutlined: true,
        backgroundColor:
            AppTheme.bgStart, // Opaque background to block floating icons
        padding: EdgeInsets.zero,
        borderRadius: 12,
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
                  fit: BoxFit.contain, // Changed to contain to show full logo
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
      if (hasAccess && mounted) {
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

  IconData _getSportIcon(String sportName) {
    switch (sportName.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'cricket':
        return Icons.sports_cricket;
      case 'basketball':
        return Icons.sports_basketball;
      case 'f1':
        return Icons.speed;
      case 'rugby':
        return Icons.sports_rugby;
      default:
        return Icons.sports;
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
