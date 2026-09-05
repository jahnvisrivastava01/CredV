import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api_service.dart';
import '../services/user_session.dart';
import 'card_setup_screen.dart';
import 'dashboard_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _apiService = ApiService();

  final _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Please enter a valid name';
      });
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      final userId = result['userId'];

      if (userId == null) {
        throw Exception('User ID not received from server');
      }

      UserSession.instance.login(
        id: userId is int ? userId : int.parse(userId.toString()),
        userName: result['name']?.toString() ?? name,
        userEmail: result['email']?.toString() ?? email,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => CardSetupScreen(
            userId: UserSession.instance.userId!,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }

      if (!mounted) return;

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // GOOGLE SIGN-IN / SIGN-UP (combined) — same logic as LoginScreen.
  // isNewUser decides CardSetupScreen vs Dashboard, regardless of
  // which screen (Login or Register) the person tapped this from.
  // ============================================================

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Open Google account picker
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled
        return;
      }

      // Step 2: Get Google authentication credentials
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 3: Authenticate with Firebase
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Google sign-in did not return a user');
      }

      final String name = firebaseUser.displayName ?? 'Google User';
      final String email = firebaseUser.email ?? '';

      if (email.isEmpty) {
        throw Exception('Google account did not provide an email');
      }

      // Step 4: Send Google user to CredV backend
      final result = await _apiService.googleLogin(
        name: name,
        email: email,
      );

      // Step 5: Get REAL CredV database user ID
      final dynamic rawUserId = result['userId'] ?? result['id'];

      if (rawUserId == null) {
        throw Exception('User ID was not returned by server');
      }

      final int userId =
          rawUserId is int ? rawUserId : int.parse(rawUserId.toString());

      // Backend decides if user is new in CredV
      final bool isNewUser = result['isNewUser'] == true;

      // Save real backend user ID
      UserSession.instance.login(
        id: userId,
        userName: result['name']?.toString() ?? name,
        userEmail: result['email']?.toString() ?? email,
      );

      if (!mounted) return;

      // New CredV user → Card Setup
      if (isNewUser) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CardSetupScreen(
              userId: userId,
            ),
          ),
          (route) => false,
        );
      }

      // Existing CredV user → Dashboard
      else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                // =====================================================
                // APP ICON - SAME BRANDING AS LOGIN SCREEN
                // =====================================================
                Center(
                  child: Container(
                    height: 110,
                    width: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7C5CFC),
                          Color(0xFF38D9C0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38D9C0).withOpacity(0.20),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 55,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Start managing your credit smarter',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // =====================================================
                // NAME FIELD
                // =====================================================
                _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 20),

                // =====================================================
                // EMAIL FIELD
                // =====================================================
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // =====================================================
                // PASSWORD FIELD
                // =====================================================
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // =====================================================
                // CREATE ACCOUNT BUTTON
                // =====================================================
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          Colors.tealAccent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // =====================================================
                // DIVIDER
                // =====================================================
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),

                const SizedBox(height: 24),

                // =====================================================
                // GOOGLE SIGN-IN BUTTON
                // =====================================================
                SizedBox(
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(
                      _isGoogleLoading
                          ? 'Signing in...'
                          : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // =====================================================
                // LOGIN NAVIGATION
                // =====================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white60,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.tealAccent,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1C22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.white24,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.tealAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}