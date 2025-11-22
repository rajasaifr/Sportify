import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify_app/services/auth_service.dart';
import 'package:sportify_app/theme/app_theme.dart';
import 'package:sportify_app/widgets/floating_emitter.dart';
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

  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isSignup = false;

  bool get _isAnyLoading => _isEmailLoading || _isGoogleLoading;

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
      Logger.error('FirebaseAuthException: ${e.code}', error: e, tag: 'LoginScreen');
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
      Logger.error('Unexpected error during ${_isSignup ? "signup" : "login"}', error: e, stackTrace: stackTrace, tag: 'LoginScreen');
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
      if (result != null && _isSignup)
        _showSnackBar('Account created successfully!');
    } catch (e) {
      _showSnackBar('Google Sign-In failed.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI SECTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Background: Darker Radial Gradient
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Color(0xFF0A0A0F), // Much darker purple
              Color(0xFF000000), // Pure black
            ],
          ),
        ),
        child: SafeArea(
          // --- STACK TO LAYER EMITTER BEHIND CARD ---
          child: Stack(
            children: [
              // 1. FLOATING EMITTER (Background Layer)
              Positioned.fill(
                child: FloatingEmitter(
                  // --- JPG ASSET PATHS ---
                  assetPaths: const [
                    'assets/images/floating_icons/basketball.jpg',
                    'assets/images/floating_icons/bat.jpg',
                    'assets/images/floating_icons/glove.jpg',
                    'assets/images/floating_icons/helmet.jpg',
                    'assets/images/floating_icons/racket.jpg',
                    'assets/images/floating_icons/soccer_ball.jpg',
                  ],
                  emissionInterval: const Duration(milliseconds: 500),
                  particleDuration: const Duration(seconds: 20),
                  particleSizeMin: 25.0, // Smaller icons
                  particleSizeMax: 45.0, // Smaller icons
                  maxParticles: 16, // Slightly increased
                ),
              ),

              // 2. LOGIN CARD (Foreground Layer)
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    // The Main Login Card (Dark Box Style)
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A), // Card color
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- FINAL LOGO SECTION ---
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.6),
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/App_Icon.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- GRADIENT TEXT ---
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, AppTheme.primary],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Text(
                            _isSignup ? 'Create\nAccount' : 'Welcome\nBack',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSignup ? 'Enter the arena.' : 'Live the game.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textFaint,
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildNeonInput(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        if (_isSignup) ...[
                          _buildNeonInput(
                            controller: _nameController,
                            label: "Username",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildNeonInput(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),

                        if (!_isSignup)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                    color: AppTheme.textFaint, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 24),

                        if (!_isSignup) const SizedBox(height: 8),

                        // --- MAIN BUTTON ---
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isAnyLoading ? null : _submit,
                            child: _isEmailLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isSignup ? 'CREATE ACCOUNT' : 'LOG IN',
                                    style: const TextStyle(
                                        fontSize: 14, letterSpacing: 1.0),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- DIVIDER & SOCIAL ---
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.1))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text("OR",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.2),
                                      fontSize: 10)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.1))),
                          ],
                        ),
                        const SizedBox(height: 24),

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
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isSignup
                                        ? 'Sign up with Google'
                                        : 'Log in with Google',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.1)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- TOGGLE ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignup ? 'Already in?' : 'New here?',
                              style: const TextStyle(
                                  color: AppTheme.textFaint, fontSize: 13),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isSignup = !_isSignup),
                              child: Text(
                                _isSignup ? 'Log In' : 'Sign Up',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildNeonInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto, // Label floats to top when focused/filled
        labelStyle: TextStyle(
          color: AppTheme.textFaint,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textFaint),
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primary,
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

