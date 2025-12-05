import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/utils/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  late FocusNode _nameFocusNode;

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isSignup = false;
  bool _obscurePassword = true;

  bool get _isAnyLoading => _isEmailLoading || _isGoogleLoading;

  // New color scheme: Red, Dark Bluish Green, and Black
  static const Color darkBluishGreen = Color(0xFF0F4C3A);
  static const Color lightBluishGreen = Color(0xFF2D5A47);
  static const Color backgroundColor = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _nameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // --- LOGIC SECTION ---
  Future<void> _submit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isEmailLoading = true);

    try {
      if (_isSignup) {
        Logger.debug('Starting signup process', tag: 'LoginScreen');
        final user = await authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: name,
        );

        if (user != null) {
          Logger.info('Signup successful', tag: 'LoginScreen');
          _showSnackBar('Account created! Welcome.');
        } else {
          Logger.warning('Signup returned null', tag: 'LoginScreen');
          _showSnackBar('Failed to create account. Please try again.');
        }
      } else {
        Logger.debug('Starting login process', tag: 'LoginScreen');
        await authService.signInWithEmail(
          email: email,
          password: password,
        );
        Logger.info('Login successful', tag: 'LoginScreen');
      }
    } on FirebaseAuthException catch (e) {
      Logger.error('FirebaseAuthException: ${e.code}',
          error: e, tag: 'LoginScreen');
      String message = 'An error occurred';
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password. Please try again.';
          break;
        case 'email-already-in-use':
          message =
              'The account already exists for that email. Please sign in instead.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'weak-password':
          message =
              'The password provided is too weak. Please use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'Authentication failed. Please try again.';
      }
      _showSnackBar(message);
    } catch (e, stackTrace) {
      Logger.error('Unexpected error during ${_isSignup ? "signup" : "login"}',
          error: e, stackTrace: stackTrace, tag: 'LoginScreen');
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isGoogleLoading = true);
    try {
      final result = await authService.signInWithGoogle();
      if (result != null && _isSignup) {
        _showSnackBar('Account created successfully!');
      }
    } catch (e) {
      Logger.error('Google Sign-In exception', error: e, tag: 'LoginScreen');
      _showSnackBar('Google Sign-In failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: darkBluishGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Left Side - Image (70%)
          Expanded(
            flex: 7, // Changed from 1 to 7 (70%)
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image with error handling
                Image.network(
                  'https://images.pexels.com/photos/269948/pexels-photo-269948.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: backgroundColor,
                      child: const Center(
       
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: backgroundColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Content overlay
                const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Align(
                      alignment: Alignment.topLeft, // Top left
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Left align text
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SPORTIFY',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Live the game',
                            style: TextStyle(
                              fontSize: 18,
                              color: lightBluishGreen,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right Side - Login Form (30%)
          Expanded(
            flex: 3, // Changed from 1 to 3 (30%)
            child: Container(
              color: backgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(50), // Increased from 40 to 50
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(0), // Changed from 20 to 0 (sharp corners)
                      border: Border.all(
                        color: darkBluishGreen.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: darkBluishGreen.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          _isSignup ? 'Create Account' : 'Welcome Back',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignup
                              ? 'Join the arena'
                              : 'Sign in to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Email Input
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocusNode,
                          onSubmitted: () {
                            if (_isSignup) {
                              _nameFocusNode.requestFocus();
                            } else {
                              _passwordFocusNode.requestFocus();
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Name Input (only for signup)
                        if (_isSignup) ...[
                          _buildInputField(
                            controller: _nameController,
                            label: 'Username',
                            icon: Icons.person_outline,
                            focusNode: _nameFocusNode,
                            onSubmitted: () {
                              _passwordFocusNode.requestFocus();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Password Input
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          focusNode: _passwordFocusNode,
                          onSubmitted: () {
                            if (!_isAnyLoading) {
                              _submit();
                            }
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isAnyLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBluishGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0), // Changed from 12 to 0
                              ),
                              elevation: 0,
                            ),
                            child: _isEmailLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isSignup ? 'CREATE ACCOUNT' : 'SIGN IN',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Google Sign In Button
                        SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isAnyLoading ? null : _googleSignIn,
                            icon: _isGoogleLoading
                                ? const SizedBox.shrink()
                                : _buildGoogleIcon(),
                            label: _isGoogleLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isSignup
                                        ? 'Sign up with Google'
                                        : 'Sign in with Google',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0), // Changed from 12 to 0
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Toggle Sign Up / Sign In
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignup ? 'Already have an account?' : 'Don\'t have an account?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSignup = !_isSignup;
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _nameController.clear();
                                });
                              },
                              child: Text(
                                _isSignup ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  color: lightBluishGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onFieldSubmitted: (_) => onSubmitted?.call(),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: lightBluishGreen,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0), // Changed from 12 to 0
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0), // Changed from 12 to 0
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0), // Changed from 12 to 0
          borderSide: const BorderSide(
            color: lightBluishGreen,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 8),
      child: Image.asset(
        'assets/images/Google_Logo.jpg',
        width: 18,
        height: 18,
        fit: BoxFit.contain,
      ),
    );
  }
}
