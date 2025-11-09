import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ADD THIS IMPORT
import '../services/auth_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignup = false;
  String _connectionStatus = 'Testing connection...';
  
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _testBackendConnection();
  }

  Future<void> _testBackendConnection() async {
    try {
      bool isConnected = await _apiService.testConnection();
      setState(() {
        _connectionStatus = isConnected 
            ? '✅ Connected to backend'
            : '❌ Backend not reachable';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Connection test failed: $e';
      });
    }
  }Future<void> _submit() async {
  // Basic validation
  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
    _showSnackBar('Please fill in all fields');
    return;
  }

  // Password length validation
  if (_passwordController.text.length < 6) {
    _showSnackBar('Password must be at least 6 characters long');
    return;
  }

  // Email format validation
  if (!_emailController.text.contains('@')) {
    _showSnackBar('Please enter a valid email address');
    return;
  }

  if (_isSignup && _nameController.text.isEmpty) {
    _showSnackBar('Please enter your name');
    return;
  }

  setState(() => _isLoading = true);

  try {
    User? user;
    
    if (_isSignup) {
      user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    } else {
      user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }

    if (user != null) {
      _showSnackBar(_isSignup ? 'Account created!' : 'Welcome back!');
      print('🎉 SUCCESS! User UID: ${user.uid}');
      
      // Clear form
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
    } else {
      _showSnackBar('Failed to authenticate');
    }
    
  } catch (e) {
    _showSnackBar('Error: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showSnackBar(String message) {
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Connection status
            Text(
              _connectionStatus,
              style: TextStyle(
                color: _connectionStatus.contains('✅') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
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
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              hintText: 'At least 6 characters',
              errorText: _passwordController.text.isNotEmpty && _passwordController.text.length < 6 
                  ? 'Password must be 6+ characters' 
                  : null,
            ),
            obscureText: true,
            onChanged: (value) {
              setState(() {}); // Refresh UI to show/hide error
            },
          ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : Text(_isSignup ? 'Sign Up' : 'Sign In'),
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
    );
  }
}