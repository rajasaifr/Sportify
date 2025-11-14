import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- ADD THIS
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

  // We no longer create the instance here
  // final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isSignup = false;

  Future<void> _submit() async {
    // --- THIS IS THE FIX ---
    // Get the shared service from Provider
    final authService = Provider.of<AuthService>(context, listen: false);
    // --- END OF FIX ---

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }
    if (_isSignup && _nameController.text.isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignup) {
        await authService.signUpWithEmail( // Use the shared service
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );
        _showSnackBar('Account created! Please log in.');
      } else {
        await authService.signInWithEmail( // Use the shared service
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    // --- THIS IS THE FIX ---
    final authService = Provider.of<AuthService>(context, listen: false);
    // --- END OF FIX ---

    setState(() => _isLoading = true);
    try {
      await authService.signInWithGoogle(); // Use the shared service
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sportify'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignup ? 'Create Account' : 'Sign In',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              
              if (_isSignup)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_isSignup) const SizedBox(height: 16),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  hintText: 'At least 6 characters',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isSignup ? 'Sign Up' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 28), // Placeholder
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _isLoading ? null : _googleSignIn,
                  label: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign in with Google'),
                ),
              ),
              
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignup = !_isSignup;
                  });
                },
                child: Text(
                  _isSignup
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}