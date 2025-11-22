import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Separate loading states
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;

  bool _isSignup = false;

  // Helper to disable buttons if ANY loading is happening
  bool get _isAnyLoading => _isEmailLoading || _isGoogleLoading;

  Future<void> _submit() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Validate fields
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }
    
    if (_isSignup) {
      if (name.isEmpty) {
        _showSnackBar('Please enter your name');
        return;
      }
      
      // Basic email validation
      if (!email.contains('@') || !email.contains('.')) {
        _showSnackBar('Please enter a valid email address');
        return;
      }
      
      // Password length validation
      if (password.length < 6) {
        _showSnackBar('Password must be at least 6 characters');
        return;
      }
    }

    // Start Email Loading
    setState(() => _isEmailLoading = true);

    try {
      if (_isSignup) {
        print('🔄 Starting signup process...');
        final user = await authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: name,
        );
        
        if (user != null) {
          print('✅ Signup successful!');
          _showSnackBar('Account created! Welcome.');
        } else {
          print('❌ Signup returned null');
          _showSnackBar('Failed to create account. Please try again.');
        }
      } else {
        print('🔄 Starting login process...');
        await authService.signInWithEmail(
          email: email,
          password: password,
        );
        print('✅ Login successful!');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'An error occurred';
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'user-not-found':
        case 'wrong-password':
          message = 'Invalid email or password. Please try again.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email. Please sign in instead.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak. Please use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = e.message ?? 'Authentication failed. Please try again.';
      }
      _showSnackBar(message);
    } catch (e, stackTrace) {
      print('❌ Unexpected error during ${_isSignup ? "signup" : "login"}: $e');
      print('Stack trace: $stackTrace');
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Start Google Loading
    setState(() => _isGoogleLoading = true);

    try {
      final result = await authService.signInWithGoogle();
      if (result == null) {
        // User cancelled the sign-in
        _showSnackBar('Sign in cancelled');
      } else {
        // Google sign-in automatically handles both login and signup
        // If it's a new user, it creates an account; if existing, it logs in
        if (_isSignup) {
          _showSnackBar('Account created successfully!');
        }
      }
    } catch (e) {
      String errorMessage = 'Error signing in with Google';
      final errorString = e.toString();
      if (errorString.contains('Client ID') || errorString.contains('not configured')) {
        errorMessage = 'Google Sign-In is not configured. Please configure your Google Client ID in web/index.html';
      } else {
        errorMessage = 'Error: $errorString';
      }
      _showSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // Color scheme
  static const Color purpleButton = Color(0xFF6C5CE7); // Purple for primary button
  static const Color linkColor = Color(0xFF6C5CE7); // Purple for links

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // Match container gradient start color
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
              child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e), // Dark blue-black
                    Color(0xFF16213e), // Medium blue-black
                    Color(0xFF0f3460), // Darker blue
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    _isSignup ? 'Sign up to your account' : 'Log in to your account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Email/Mobile Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email/Mobile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email or mobile number',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: purpleButton, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isSignup) const SizedBox(height: 20),

                  // Name Field (only for signup)
                  if (_isSignup)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: purpleButton, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Password Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: purpleButton, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Forgot Password (only for login, above login button)
                  if (!_isSignup)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password
                          _showSnackBar('Forgot password feature coming soon');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: linkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  if (!_isSignup) const SizedBox(height: 12),

                  // Primary Login/Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isAnyLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purpleButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                              _isSignup ? 'Sign up' : 'Log in',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Google Sign In Button (below login button)
                  _buildSocialButton(
                    icon: _buildGoogleIcon(),
                    text: _isSignup ? 'Sign up with Google' : 'Log in with Google',
                    onPressed: _isAnyLoading ? null : _googleSignIn,
                    isLoading: _isGoogleLoading,
                  ),

                  const SizedBox(height: 16),

                  // Sign Up / Sign In Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(
                        _isSignup
                            ? 'Already have an account? '
                            : 'New to Sportify? ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignup = !_isSignup;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isSignup ? 'Sign in' : 'Sign up',
                          style: TextStyle(
                            color: linkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon,
        label: isLoading
            ? const SizedBox.shrink()
            : Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomPaint(
        painter: GoogleIconPainter(),
      ),
    );
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// Custom painters for social media icons
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Google G colors
    // Blue part
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.5, size.height), paint);
    
    // Red part
    paint.color = const Color(0xFFEA4335);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.5, size.height * 0.5), paint);
    
    // Yellow part
    paint.color = const Color(0xFFFBBC05);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.5, size.height * 0.5, size.width * 0.5, size.height * 0.5), paint);
    
    // Green part (overlay)
    paint.color = const Color(0xFF34A853);
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

