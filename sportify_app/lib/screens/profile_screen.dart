import 'dart:async';
// Image upload functionality disabled - these imports not needed for now
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Image picker disabled for now - photo change functionality removed
// import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sportify_app/models/user_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/profile_service.dart';
import 'package:sportify_app/theme/app_theme.dart';
import 'package:sportify_app/widgets/floating_emitter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // Image picker disabled for now - photo change functionality removed
  // final ImagePicker _imagePicker = ImagePicker();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  List<String> _selectedTeams = [];
  String? _selectedSport; // Track selected sport
  bool _isLoading = false;
  
  // Map of sports to their teams
  static const Map<String, List<String>> _sportsTeams = {
    'Basketball': [
      'Los Angeles Lakers',
      'Golden State Warriors',
      'Chicago Bulls',
      'Boston Celtics',
      'Miami Heat',
      'Toronto Raptors',
      'Milwaukee Bucks',
      'Phoenix Suns',
      'Denver Nuggets',
      'Dallas Mavericks',
      'Philadelphia 76ers',
      'Brooklyn Nets',
      'New York Knicks',
      'Los Angeles Clippers',
      'Portland Trail Blazers',
    ],
    'Soccer': [
      'Real Madrid',
      'FC Barcelona',
      'Manchester United',
      'Liverpool FC',
      'Manchester City',
      'Chelsea FC',
      'Arsenal FC',
      'Paris Saint-Germain',
      'Bayern Munich',
      'Juventus',
      'AC Milan',
      'Inter Milan',
      'Atletico Madrid',
      'Tottenham Hotspur',
      'Borussia Dortmund',
    ],
    'Football': [
      'Kansas City Chiefs',
      'Buffalo Bills',
      'Dallas Cowboys',
      'Green Bay Packers',
      'San Francisco 49ers',
      'Pittsburgh Steelers',
      'New England Patriots',
      'Tampa Bay Buccaneers',
      'Seattle Seahawks',
      'Baltimore Ravens',
      'Denver Broncos',
      'Las Vegas Raiders',
      'Miami Dolphins',
      'New York Giants',
      'Philadelphia Eagles',
    ],
    'Baseball': [
      'New York Yankees',
      'Boston Red Sox',
      'Los Angeles Dodgers',
      'Chicago Cubs',
      'Houston Astros',
      'Atlanta Braves',
      'St. Louis Cardinals',
      'San Francisco Giants',
      'New York Mets',
      'Philadelphia Phillies',
      'Toronto Blue Jays',
      'Seattle Mariners',
      'Tampa Bay Rays',
      'Minnesota Twins',
      'Cleveland Guardians',
    ],
    'Hockey': [
      'Toronto Maple Leafs',
      'Montreal Canadiens',
      'Boston Bruins',
      'Chicago Blackhawks',
      'Detroit Red Wings',
      'Pittsburgh Penguins',
      'Washington Capitals',
      'Tampa Bay Lightning',
      'Colorado Avalanche',
      'Edmonton Oilers',
      'Vancouver Canucks',
      'New York Rangers',
      'Los Angeles Kings',
      'Vegas Golden Knights',
      'New Jersey Devils',
    ],
  };
  // Image selection disabled - these fields not used for now
  // Uint8List? _selectedImageBytes;
  String? _currentProfilePicUrl;
  // String? _pendingProfilePicUrl; // Track the URL we just uploaded
  // DateTime? _originalCreatedAt;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);

    try {
      final user = authService.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        final userProfile = await profileService.getUserProfile(user.uid);
        if (userProfile != null && mounted) {
          setState(() {
            _displayNameController.text = userProfile.displayName ?? '';
            _bioController.text = userProfile.bio ?? '';
            _selectedTeams = userProfile.favoriteTeams ?? [];
            _currentProfilePicUrl = userProfile.profilePicUrl;
            // _originalCreatedAt = userProfile.createdAt; // Image upload disabled
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final profileService =
          Provider.of<ProfileService>(context, listen: false);

      final currentUser = authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user logged in. Please sign in again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // Image upload functionality disabled for now
      // Upload image to Firebase Storage if a new image was selected
      // String? profilePicUrl = _currentProfilePicUrl;
      // bool imageUploadSucceeded = false;
      
      // Image selection disabled - skip upload
      /*
      if (_selectedImageBytes != null) {
        try {
          print('═══════════════════════════════════════');
          print('🖼️  STARTING IMAGE UPLOAD');
          print('User ID: ${currentUser.uid}');
          print('Image size: ${(_selectedImageBytes!.length / 1024).toStringAsFixed(1)}KB');
          print('═══════════════════════════════════════');
          
          final uploadedUrl = await _uploadProfileImage(
            currentUser.uid,
            _selectedImageBytes!,
          ).timeout(
            const Duration(seconds: 65),
            onTimeout: () {
              print('❌ TIMEOUT: Image upload timed out after 65 seconds');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image upload timed out. The image may be too large. Profile saved without new image.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
              throw TimeoutException('Image upload timeout', const Duration(seconds: 65));
            },
          );
          
          print('✅ Image upload successful. URL: $uploadedUrl');
          
          // Only update profilePicUrl if upload succeeded and we got a valid URL
          if (uploadedUrl.isNotEmpty) {
            profilePicUrl = uploadedUrl;
            imageUploadSucceeded = true;
            print('✅ Profile picture URL set to: $profilePicUrl');
          } else {
            print('⚠️  WARNING: Upload returned empty URL');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image upload failed: No URL returned. Profile saved without new image.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e, stackTrace) {
          print('═══════════════════════════════════════');
          print('❌ ERROR UPLOADING IMAGE');
          print('Error: $e');
          print('Error type: ${e.runtimeType}');
          print('Full error string: ${e.toString()}');
          print('Stack trace: $stackTrace');
          print('═══════════════════════════════════════');
          
          // Always show error to user with more details
          if (mounted) {
            String errorMessage = 'Failed to upload image';
            if (e is TimeoutException) {
              errorMessage = 'Image upload timed out. Please try a smaller image or check your internet connection.';
            } else if (e.toString().contains('permission') || e.toString().contains('unauthorized') || e.toString().contains('403')) {
              errorMessage = 'Permission denied. Please check Firebase Storage rules allow authenticated users to upload.';
            } else if (e.toString().contains('network') || e.toString().contains('connection') || e.toString().contains('SocketException')) {
              errorMessage = 'Network error. Please check your internet connection.';
            } else {
              errorMessage = 'Failed to upload image: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          // Continue saving profile even if image upload fails
          imageUploadSucceeded = false;
        }
      }
      */

      // Determine the final profilePicUrl to save (keep existing, no new uploads)
      final finalProfilePicUrl = _currentProfilePicUrl;
      
      print('Final profile picture URL: $finalProfilePicUrl');
      print('Image upload disabled - preserving existing profile picture');
      
      // Build update map - only include profilePicUrl if we have a new value to save
      final updateData = <String, dynamic>{
        'displayName': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'favoriteTeams': _selectedTeams,
        'role': UserRole.user.name,
      };
      
      // Image upload disabled - don't update profilePicUrl
      // Only include profilePicUrl if we have a NEW value (successful upload)
      // if (_selectedImageBytes != null && imageUploadSucceeded && profilePicUrl != null && profilePicUrl.isNotEmpty) {
      //   updateData['profilePicUrl'] = profilePicUrl;
      //   print('Including profilePicUrl in update: $profilePicUrl');
      // } else {
      //   print('Not including profilePicUrl in update (preserving existing)');
      // }
      print('Not including profilePicUrl in update (image upload disabled)');
      
      print('Updating profile with data: $updateData');
      
      // Use updateUserFields to only update specific fields
      await profileService.updateProfileFields(
        uid: currentUser.uid,
        fields: updateData,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Profile update timed out. Please check your connection and try again.');
        },
      );

      print('Profile update successful');

      // Update current profile pic URL after successful save
      if (mounted) {
        setState(() {
          _currentProfilePicUrl = finalProfilePicUrl;
          // Image upload disabled - clear any pending state
          // _pendingProfilePicUrl = null; // Image upload disabled
          // _selectedImageBytes = null; // Image selection disabled
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error saving profile: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Image upload functionality disabled - methods commented out
  /*
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      print('Compressing image: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB');
      
      // Decode the image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      print('Original image size: ${image.width}x${image.height}');
      
      // Calculate new size (max 250x250 for profile picture - smaller for faster upload)
      final maxSize = 250.0;
      double width = image.width.toDouble();
      double height = image.height.toDouble();
      
      if (width > maxSize || height > maxSize) {
        if (width > height) {
          height = (height * maxSize / width);
          width = maxSize;
        } else {
          width = (width * maxSize / height);
          height = maxSize;
        }
      }
      
      print('Resizing to: ${width.toInt()}x${height.toInt()}');
      
      // Resize the image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width, height),
        Paint(),
      );
      final picture = recorder.endRecording();
      final resizedImage = await picture.toImage(width.toInt(), height.toInt());
      
      // Convert to PNG (smaller than raw, though JPEG would be better but requires a package)
      final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to compress image - byteData is null');
      }
      
      final compressedBytes = byteData.buffer.asUint8List();
      final compressionRatio = ((1 - compressedBytes.length / imageBytes.length) * 100).toStringAsFixed(1);
      print('Image compressed from ${(imageBytes.length / 1024).toStringAsFixed(1)}KB to ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB (${compressionRatio}% reduction)');
      
      // If compression actually made it larger, return original
      if (compressedBytes.length >= imageBytes.length) {
        print('Compression made image larger, using original');
        return imageBytes;
      }
      
      return compressedBytes;
    } catch (e, stackTrace) {
      print('Error compressing image: $e');
      print('Stack trace: $stackTrace');
      // If compression fails, return original
      return imageBytes;
    }
  }

  Future<String> _uploadProfileImage(String userId, Uint8List imageBytes) async {
    try {
      print('_uploadProfileImage called for user: $userId');
      print('Original image bytes length: ${imageBytes.length}');
      
      // Always compress image to ensure it's small enough for fast upload
      Uint8List processedBytes = imageBytes;
      final originalSizeKB = imageBytes.length / 1024;
      
      if (originalSizeKB > 100) { // If larger than 100KB, compress
        print('Image is ${originalSizeKB.toStringAsFixed(1)}KB, compressing...');
        processedBytes = await _compressImage(imageBytes);
        final compressedSizeKB = processedBytes.length / 1024;
        print('Compressed to ${compressedSizeKB.toStringAsFixed(1)}KB');
        
        // If still too large after compression, try one more time with smaller size
        if (compressedSizeKB > 200) {
          print('Still large after compression, compressing again...');
          processedBytes = await _compressImage(processedBytes);
          print('Final size: ${(processedBytes.length / 1024).toStringAsFixed(1)}KB');
        }
      } else {
        print('Image is already small enough: ${originalSizeKB.toStringAsFixed(1)}KB');
      }
      
      final storage = FirebaseStorage.instance;
      
      // Detect format and use appropriate extension
      String fileExtension = 'jpg';
      String contentType = 'image/jpeg';
      
      // Detect original format
      if (processedBytes.length >= 4) {
        if (processedBytes[0] == 0x89 && 
            processedBytes[1] == 0x50 && 
            processedBytes[2] == 0x4E && 
            processedBytes[3] == 0x47) {
          fileExtension = 'png';
          contentType = 'image/png';
          print('Detected PNG format');
        } else if (processedBytes.length >= 3 && 
                   processedBytes[0] == 0xFF && 
                   processedBytes[1] == 0xD8 && 
                   processedBytes[2] == 0xFF) {
          fileExtension = 'jpg';
          contentType = 'image/jpeg';
          print('Detected JPEG format');
        }
      }
      
      final filePath = 'profile_pictures/$userId.$fileExtension';
      print('Uploading to path: $filePath');
      print('Content type: $contentType');
      print('Final file size: ${(processedBytes.length / 1024).toStringAsFixed(1)}KB');
      
      final ref = storage.ref().child('profile_pictures').child('$userId.$fileExtension');
      
      print('Starting upload task...');
      print('User ID: $userId');
      print('Storage bucket: ${storage.app.options.storageBucket}');
      
      // Upload the image with timeout
      UploadTask uploadTask;
      try {
        uploadTask = ref.putData(
          processedBytes,
          SettableMetadata(
            contentType: contentType,
            cacheControl: 'max-age=3600',
          ),
        );
        print('✅ Upload task created successfully');
      } catch (e) {
        print('❌ Failed to create upload task: $e');
        rethrow;
      }
      
      print('Upload task created, waiting for completion...');
      print('File size: ${(processedBytes.length / 1024).toStringAsFixed(1)}KB');
      
      // Wait for upload to complete (30 seconds for better reliability)
      try {
        await uploadTask.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('❌ Upload timeout after 30 seconds');
            print('File size was: ${(processedBytes.length / 1024).toStringAsFixed(1)}KB');
            uploadTask.cancel();
            throw TimeoutException('Image upload timeout after 30 seconds. The image may still be too large. Please try selecting a smaller image.', const Duration(seconds: 30));
          },
        );
        print('✅ Upload completed successfully');
      } catch (e) {
        print('❌ Upload failed: $e');
        print('Upload task state: ${uploadTask.snapshot.state}');
        print('Bytes transferred: ${uploadTask.snapshot.bytesTransferred} / ${uploadTask.snapshot.totalBytes}');
        rethrow;
      }
      
      print('Upload completed, getting download URL...');
      
      // Get the download URL with timeout
      final downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Failed to get download URL - timeout');
          throw TimeoutException('Failed to get download URL', const Duration(seconds: 10));
        },
      );
      
      print('Download URL received: $downloadUrl');
      
      // Verify we got a valid URL
      if (downloadUrl.isEmpty) {
        print('Error: Received empty download URL');
        throw Exception('Received empty download URL');
      }
      
      print('Image upload successful! URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      print('Error in _uploadProfileImage: $e');
      print('Stack trace: $stackTrace');
      // Re-throw with more context
      throw Exception('Failed to upload profile image: $e');
    }
  }
  */

  void _signOut() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

  void _onTeamsUpdated(List<String> teams) {
    setState(() {
      _selectedTeams = teams;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
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
            SafeArea(
              child: Column(
                children: [
                  // AppBar
                  Container(
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
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.textMain),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'MANAGE ACCOUNT',
                          style: TextStyle(
                            color: AppTheme.textMain,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A), // Card color
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(40.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top section with profile picture and basic info side by side (or stacked on small screens)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 600;
                                    if (isWide) {
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Profile Picture Section - aligned with input fields
                                          Padding(
                                            padding: const EdgeInsets.only(top: 50.0), // Align with first input field
                                            child: _buildProfilePictureSection(),
                                          ),
                                          const SizedBox(width: 40),
                                          // Basic Info Section
                                          Expanded(
                                            child: _buildBasicInfoSection(),
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          _buildProfilePictureSection(),
                                          const SizedBox(height: 24),
                                          _buildBasicInfoSection(),
                                        ],
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 32),
                                _buildPreferencesSection(),
                                const SizedBox(height: 32),
                                _buildActionButtons(),
                                const SizedBox(height: 20),
                                Divider(color: Colors.white.withValues(alpha: 0.1)),
                                const SizedBox(height: 20),
                                // Sign Out Button
                                _buildSignOutButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final currentUser = authService.currentUser;

    return StreamBuilder<UserModel?>(
      stream: currentUser != null
          ? profileService.getUserProfileStream(currentUser.uid)
          : Stream.value(null),
      builder: (context, snapshot) {
        final userModel = snapshot.data;
        final displayName = userModel?.displayName ?? currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'U';
        final profilePicUrl = userModel?.profilePicUrl ?? currentUser?.photoURL;
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

        // Image selection disabled - no need to clear pending state
        // if (_pendingProfilePicUrl != null && 
        //     profilePicUrl == _pendingProfilePicUrl && 
        //     _selectedImageBytes != null) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     if (mounted) {
        //       setState(() {
        //         _selectedImageBytes = null;
        //         _pendingProfilePicUrl = null;
        //       });
        //     }
        //   });
        // }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primary,
                backgroundImage: profilePicUrl != null
                    ? NetworkImage(profilePicUrl) as ImageProvider?
                    : null,
                child: profilePicUrl == null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            // Change Photo button removed - functionality disabled for now
          ],
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textMain,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _displayNameController,
          style: const TextStyle(color: AppTheme.textMain),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: const TextStyle(color: AppTheme.textFaint),
            floatingLabelStyle: const TextStyle(color: AppTheme.primary),
            prefixIcon: const Icon(Icons.person, color: AppTheme.textFaint, size: 20),
            filled: true,
            fillColor: AppTheme.inputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Display name is required';
            }
            if (value.length < 2) {
              return 'Display name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          style: const TextStyle(color: AppTheme.textMain),
          decoration: InputDecoration(
            labelText: 'Bio (Optional)',
            labelStyle: const TextStyle(color: AppTheme.textFaint),
            floatingLabelStyle: const TextStyle(color: AppTheme.primary),
            alignLabelWithHint: true,
            filled: true,
            fillColor: AppTheme.inputFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
          ),
          maxLines: 3,
          validator: (value) {
            if (value != null && value.length > 500) {
              return 'Bio must be less than 500 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sports Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textMain,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a sport and choose your favorite teams',
          style: TextStyle(
            color: AppTheme.textFaint.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        _buildSportDropdown(),
        if (_selectedSport != null) ...[
          const SizedBox(height: 20),
          _buildTeamSelection(),
        ],
      ],
    );
  }
  
  Widget _buildSportDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedSport != null
              ? AppTheme.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSport,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Select a sport',
          hintStyle: TextStyle(
            color: AppTheme.textFaint.withValues(alpha: 0.6),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.sports,
            color: _selectedSport != null ? AppTheme.primary : AppTheme.textFaint,
            size: 22,
          ),
        ),
        dropdownColor: AppTheme.inputFill,
        style: const TextStyle(
          color: AppTheme.textMain,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppTheme.primary,
          size: 28,
        ),
        items: _sportsTeams.keys.map((sport) {
          return DropdownMenuItem<String>(
            value: sport,
            child: Row(
              children: [
                Icon(
                  _getSportIcon(sport),
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  sport,
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedSport = newValue;
            // Remove teams that don't belong to the newly selected sport
            if (newValue != null && _sportsTeams.containsKey(newValue)) {
              final teamsForSport = _sportsTeams[newValue]!;
              _selectedTeams.removeWhere((team) => !teamsForSport.contains(team));
              _onTeamsUpdated(_selectedTeams);
            } else {
              // If no sport selected, clear all selections
              _selectedTeams.clear();
              _onTeamsUpdated(_selectedTeams);
            }
          });
        },
      ),
    );
  }
  
  IconData _getSportIcon(String sport) {
    switch (sport) {
      case 'Basketball':
        return Icons.sports_basketball;
      case 'Soccer':
        return Icons.sports_soccer;
      case 'Football':
        return Icons.sports_football;
      case 'Baseball':
        return Icons.sports_baseball;
      case 'Hockey':
        return Icons.sports_hockey;
      default:
        return Icons.sports;
    }
  }

  Widget _buildTeamSelection() {
    // Get teams for the selected sport, or empty list if no sport selected
    final List<String> availableTeams = _selectedSport != null
        ? (_sportsTeams[_selectedSport] ?? [])
        : [];

    if (availableTeams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No teams available for this sport',
            style: TextStyle(
              color: AppTheme.textFaint.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTeams.map((team) {
        final isSelected = _selectedTeams.contains(team);
        return FilterChip(
          label: Text(
            team,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textFaint,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                _selectedTeams.remove(team);
              } else {
                _selectedTeams.add(team);
              }
            });
            _onTeamsUpdated(_selectedTeams);
          },
          checkmarkColor: Colors.white,
          selectedColor: AppTheme.primary,
          backgroundColor: AppTheme.inputFill,
          side: BorderSide(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 10,
          shadowColor: AppTheme.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: _isLoading ? null : _saveProfile,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'SAVE CHANGES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
          foregroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.redAccent.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          elevation: 0,
        ),
        onPressed: _signOut,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'SIGN OUT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // Image picker methods disabled - photo change functionality removed for now
  /*
  void _showImageSourceDialog(BuildContext context) {
    // Disabled - photo change functionality removed
  }

  Widget _buildImageSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Disabled - photo change functionality removed
    return const SizedBox.shrink();
  }

  Future<void> _pickImage(ImageSource source) async {
    // Disabled - photo change functionality removed
  }
  */
}
