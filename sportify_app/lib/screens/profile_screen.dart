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
import 'package:sportify_app/models/sport_model.dart';
import 'package:sportify_app/models/team_model.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/services/profile_service.dart';
import 'package:sportify_app/services/firestore_service.dart';
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
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late FocusNode _currentPasswordFocusNode;
  late FocusNode _newPasswordFocusNode;
  late FocusNode _confirmPasswordFocusNode;
  List<String> _selectedTeams = [];
  String? _selectedSport; // Track selected sport name
  bool _isLoading = false;
  bool _isChangingPassword = false;
  bool _showChangePasswordForm = false;
  
  // Database data
  List<Sport> _availableSports = [];
  List<Team> _availableTeams = [];
  bool _isLoadingSports = false;
  bool _isLoadingTeams = false;
  bool _isEmailPasswordUser = true; // Assume email/password by default
  
  String? _currentProfilePicUrl;
  // String? _pendingProfilePicUrl; // Track the URL we just uploaded
  // DateTime? _originalCreatedAt;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _currentPasswordFocusNode = FocusNode();
    _newPasswordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();
    _loadCurrentUser();
    _checkSignInProvider(); // Check if user is email/password or OAuth
    _loadSports(); // Load sports from database
  }

  Future<void> _loadSports() async {
    setState(() => _isLoadingSports = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final sports = await firestoreService.getSports(limit: 100);
      if (mounted) {
        setState(() {
          _availableSports = sports;
          _isLoadingSports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSports = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sports: $e')),
        );
      }
    }
  }

  Future<void> _loadTeamsForSport(String sportName) async {
    setState(() => _isLoadingTeams = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final teams = await firestoreService.getTeamsBySport(sportName, limit: 100);
      if (mounted) {
        setState(() {
          _availableTeams = teams;
          _isLoadingTeams = false;
          // Remove teams that don't belong to the newly selected sport
          _selectedTeams.removeWhere((teamName) {
            return !teams.any((team) => team.name == teamName);
          });
          _onTeamsUpdated(_selectedTeams);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeams = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
      }
    }
  }

  /// Check if the current user signed in with email/password or OAuth
  Future<void> _checkSignInProvider() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        // Check if the user has email/password provider
        // If signed in with Google/OAuth, they won't have 'password' provider
        final providers = user.providerData.map((p) => p.providerId).toList();
        
        // If the user has 'password' provider, they can change password
        // Otherwise, they only have OAuth providers (like google.com)
        _isEmailPasswordUser = providers.contains('password');
        
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // If there's any error, assume email/password for safety
      _isEmailPasswordUser = true;
    }
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
          });
          
          // If user has favorite teams, try to determine the sport
          if (_selectedTeams.isNotEmpty) {
            // Try to find the sport by checking teams in database
            _determineSportFromTeams();
          }
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

  Future<void> _determineSportFromTeams() async {
    if (_selectedTeams.isEmpty) return;
    
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      // Get the first team to determine sport
      final firstTeam = await firestoreService.getTeamByName(_selectedTeams.first);
      if (firstTeam != null && firstTeam.sport != null && mounted) {
        setState(() {
          _selectedSport = firstTeam.sport;
        });
        // Load teams for this sport
        await _loadTeamsForSport(firstTeam.sport!);
      }
    } catch (e) {
      // Silently fail - user can manually select sport
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
    // Perform sign out and navigate back to app root so AuthWrapper can show LoginScreen
    authService.signOut().then((_) {
      if (!mounted) return;
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (_) {
        // ignore navigation errors
      }
    }).catchError((e) {
      // show error if sign out fails
      if (mounted) {
        _showSnackBar('Sign out failed: ${e.toString()}', isError: true);
      }
    });
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty) {
      _showSnackBar('Please enter your current password', isError: true);
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('New password must be at least 6 characters', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (currentPassword == newPassword) {
      _showSnackBar('New password must be different from current password', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.changePasswordWithVerification(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        // Show success message
        _showSnackBar('Password changed successfully! Signing you out...', isError: false);
        
        // Wait a moment for the user to see the message
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Sign out the user
          await authService.signOut();

          // Clear the form and reset state
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          if (mounted) {
            setState(() {
              _isChangingPassword = false;
              _showChangePasswordForm = false;
            });

            // Show final notification
            _showSnackBar('Please sign in again with your new password', isError: false);

            // Return to the app root so `AuthWrapper` can update the UI
            // (AuthWrapper is the `home` of MaterialApp and will show LoginScreen)
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChangingPassword = false);
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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
                                // Only show change password for email/password accounts
                                if (_isEmailPasswordUser)
                                  _buildChangePasswordSection(),
                                if (_isEmailPasswordUser) const SizedBox(height: 32),
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
        _buildSportSelection(),
        if (_selectedSport != null) ...[
          const SizedBox(height: 20),
          _buildTeamSelection(),
        ],
      ],
    );
  }
  
  Widget _buildSportSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedSport != null
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon on the left
          
          // Dropdown button
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSport,
                isExpanded: true,
                hint: Text(
                  'Select a sport',
                  style: TextStyle(
                    color: AppTheme.textFaint.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                ),
                dropdownColor: AppTheme.inputFill,
                style: const TextStyle(
                  color: AppTheme.textMain,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primary,
                  size: 28,
                ),
                items: _availableSports.map((sport) {
                  return DropdownMenuItem<String>(
                    value: sport.name,
                    child: Row(
                      children: [
                        Icon(
                          _getSportIcon(sport.name),
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          sport.name,
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
                    if (newValue != null) {
                      // Load teams for the selected sport
                      _loadTeamsForSport(newValue);
                    } else {
                      // If no sport selected, clear teams
                      _availableTeams.clear();
                      _selectedTeams.clear();
                      _onTeamsUpdated(_selectedTeams);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getSportIcon(String sport) {
    final sportLower = sport.toLowerCase();
    if (sportLower.contains('basketball')) {
      return Icons.sports_basketball;
    } else if (sportLower.contains('soccer') || sportLower.contains('football')) {
      return Icons.sports_soccer;
    } else if (sportLower.contains('football') && !sportLower.contains('soccer')) {
      return Icons.sports_football;
    } else if (sportLower.contains('baseball')) {
      return Icons.sports_baseball;
    } else if (sportLower.contains('hockey')) {
      return Icons.sports_hockey;
    } else if (sportLower.contains('cricket')) {
      return Icons.sports_cricket;
    } else if (sportLower.contains('f1') || sportLower.contains('racing')) {
      return Icons.speed;
    } else if (sportLower.contains('rugby')) {
      return Icons.sports_rugby;
    }
    return Icons.sports;
  }

  Widget _buildTeamSelection() {
    if (_selectedSport == null) {
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
            'Please select a sport first',
            style: TextStyle(
              color: AppTheme.textFaint.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (_isLoadingTeams) {
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
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
          ),
        ),
      );
    }

    if (_availableTeams.isEmpty) {
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
      children: _availableTeams.map((team) {
        final teamName = team.name;
        final isSelected = _selectedTeams.contains(teamName);
        return FilterChip(
          label: Text(
            teamName,
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
                _selectedTeams.remove(teamName);
              } else {
                _selectedTeams.add(teamName);
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

  Widget _buildChangePasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMain,
                letterSpacing: 1.0,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isChangingPassword
                  ? null
                  : () {
                      setState(() {
                        _showChangePasswordForm = !_showChangePasswordForm;
                        if (!_showChangePasswordForm) {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _showChangePasswordForm
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : AppTheme.primary,
                foregroundColor: _showChangePasswordForm
                    ? Colors.redAccent
                    : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                _showChangePasswordForm ? Icons.close : Icons.edit,
                size: 18,
              ),
              label: Text(
                _showChangePasswordForm ? 'CANCEL' : 'CHANGE PASSWORD',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        if (_showChangePasswordForm) ...[
          const SizedBox(height: 16),
          _buildPasswordInput(
            controller: _currentPasswordController,
            label: 'Current Password',
            icon: Icons.lock_outline_rounded,
            focusNode: _currentPasswordFocusNode,
            onSubmitted: () {
              _newPasswordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 12),
          _buildPasswordInput(
            controller: _newPasswordController,
            label: 'New Password',
            icon: Icons.lock_open_rounded,
            focusNode: _newPasswordFocusNode,
            onSubmitted: () {
              _confirmPasswordFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: 12),
          _buildPasswordInput(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            icon: Icons.lock_outline_rounded,
            focusNode: _confirmPasswordFocusNode,
            onSubmitted: () {
              if (!_isChangingPassword) _changePassword();
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: AppTheme.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isChangingPassword ? null : _changePassword,
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'UPDATE PASSWORD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      focusNode: focusNode,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(color: AppTheme.textMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textFaint),
        floatingLabelStyle: const TextStyle(color: AppTheme.primary),
        prefixIcon: Icon(icon, color: AppTheme.textFaint, size: 20),
        filled: true,
        fillColor: AppTheme.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
