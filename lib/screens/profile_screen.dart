import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();

  String _name = '';
  String _email = '';

  CreditCardModel? _card;

  bool _loadingCard = true;
  bool _notifications = true;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ============================================================
  // LOAD CURRENT LOGGED-IN USER + THEIR CARD
  // ============================================================

  Future<void> _loadUserData() async {
    _name = UserSession.instance.name ?? 'User';
    _email = UserSession.instance.email ?? '';

    final userId = UserSession.instance.userId;

    if (userId == null) {
      if (mounted) {
        setState(() {
          _loadingCard = false;
        });
      }
      return;
    }

    try {
      final card = await _api.fetchCard(userId);

      if (!mounted) return;

      setState(() {
        _card = card;
        _loadingCard = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCard = false;
      });
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _editProfile() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      barrierDismissible: !_savingProfile,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: !_savingProfile,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Colors.tealAccent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                enabled: !_savingProfile,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.tealAccent,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _savingProfile
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _savingProfile
                  ? null
                  : () async {
                      final newName = nameController.text.trim();
                      final newEmail = emailController.text.trim();

                      // Basic validation
                      if (newName.length < 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Name must contain at least 2 characters',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      if (newEmail.isEmpty ||
                          !newEmail.contains('@') ||
                          !newEmail.contains('.')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid email address',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final userId = UserSession.instance.userId;

                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User session not found'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        _savingProfile = true;
                      });

                      try {
                        // ==================================================
                        // UPDATE PROFILE IN BACKEND DATABASE
                        // ==================================================

                        final updatedUser = await _api.updateProfile(
                          userId: userId,
                          name: newName,
                          email: newEmail,
                        );

                        if (!mounted) return;

                        final updatedName =
                            updatedUser['name']?.toString() ?? newName;

                        final updatedEmail =
                            updatedUser['email']?.toString() ?? newEmail;

                        // Update current screen
                        setState(() {
                          _name = updatedName;
                          _email = updatedEmail;
                        });

                        // Update current session
                        UserSession.instance.login(
                          id: userId,
                          userName: updatedName,
                          userEmail: updatedEmail,
                        );

                        if (!mounted) return;

                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Profile updated successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        setDialogState(() {
                          _savingProfile = false;
                        });

                        String errorMessage = e
                            .toString()
                            .replaceFirst('Exception: ', '');

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: _savingProfile
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD DETAILS - CURRENT USER ONLY
  // ============================================================

  void _showCardDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: _loadingCard
              ? const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.tealAccent,
                    ),
                  ),
                )
              : _card == null
                  ? const SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'No card details available',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.credit_card,
                          size: 45,
                          color: Colors.tealAccent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Connected Card',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Bank
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.account_balance,
                            color: Colors.tealAccent,
                          ),
                          title: Text(
                            _card!.bankName,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            '•••• ${_card!.last4}',
                            style: const TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                        ),

                        const Divider(
                          color: Colors.white12,
                        ),

                        // Credit Score
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.credit_score,
                            color: Colors.tealAccent,
                          ),
                          title: const Text(
                            'Credit Score',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          trailing: Text(
                            '${_card!.creditScore}',
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        const Divider(
                          color: Colors.white12,
                        ),

                        // Credit Limit
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.tealAccent,
                          ),
                          title: const Text(
                            'Credit Limit',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          trailing: Text(
                            '₹${_card!.creditLimit.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const Divider(
                          color: Colors.white12,
                        ),

                        // Outstanding
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.money_off_csred_outlined,
                            color: Colors.orangeAccent,
                          ),
                          title: const Text(
                            'Outstanding',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          trailing: Text(
                            '₹${_card!.outstanding.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'CredV',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet,
        size: 40,
        color: Colors.tealAccent,
      ),
      children: const [
        Text(
          'A Flutter fintech portfolio project focused on credit card '
          'management, transactions, rewards and spending analytics.',
        ),
      ],
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Clear current user
    UserSession.instance.logout();

    if (!mounted) return;

    // Remove entire dashboard/navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        const SizedBox(height: 10),

        // ========================================================
        // PROFILE HEADER
        // ========================================================

        Center(
          child: CircleAvatar(
            radius: 45,
            backgroundColor: Colors.teal,
            child: Text(
              _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: Text(
            _name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 5),

        Center(
          child: Text(
            _email,
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ========================================================
        // ACCOUNT
        // ========================================================

        _sectionTitle('ACCOUNT'),

        Card(
          color: const Color(0xFF1A1A2E),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: Colors.tealAccent,
                ),
                title: const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _editProfile,
              ),

              const Divider(
                height: 1,
                color: Colors.white12,
              ),

              ListTile(
                leading: const Icon(
                  Icons.credit_card_outlined,
                  color: Colors.tealAccent,
                ),
                title: const Text(
                  'Card Details',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: _loadingCard
                    ? const Text(
                        'Loading card...',
                        style: TextStyle(color: Colors.white54),
                      )
                    : _card != null
                        ? Text(
                            '${_card!.bankName} •••• ${_card!.last4}',
                            style: const TextStyle(
                              color: Colors.white54,
                            ),
                          )
                        : const Text(
                            'No card available',
                            style: TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _showCardDetails,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ========================================================
        // PREFERENCES
        // ========================================================

        _sectionTitle('PREFERENCES'),

        Card(
          color: const Color(0xFF1A1A2E),
          child: SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: Colors.tealAccent,
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _notifications
                  ? 'Transaction alerts enabled'
                  : 'Transaction alerts disabled',
              style: const TextStyle(color: Colors.white54),
            ),
            value: _notifications,
            activeColor: Colors.tealAccent,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Notifications enabled'
                        : 'Notifications disabled',
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // ========================================================
        // APP
        // ========================================================

        _sectionTitle('APP'),

        Card(
          color: const Color(0xFF1A1A2E),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: Colors.tealAccent,
                ),
                title: const Text(
                  'About CredV',
                  style: TextStyle(color: Colors.white),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _showAbout,
              ),

              const Divider(
                height: 1,
                color: Colors.white12,
              ),

              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white54,
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
        left: 4,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.tealAccent,
        ),
      ),
    );
  }
}