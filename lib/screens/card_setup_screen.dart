import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'dashboard_screen.dart';

class CardSetupScreen extends StatefulWidget {
  final int userId;

  const CardSetupScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CardSetupScreen> createState() => _CardSetupScreenState();
}

class _CardSetupScreenState extends State<CardSetupScreen> {
  final _bankController = TextEditingController();
  final _last4Controller = TextEditingController();
  final _limitController = TextEditingController();
  final _outstandingController = TextEditingController();
  final _scoreController = TextEditingController(text: '750');

  final _api = ApiService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _bankController.dispose();
    _last4Controller.dispose();
    _limitController.dispose();
    _outstandingController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    final bankName = _bankController.text.trim();
    final last4 = _last4Controller.text.trim();

    final creditLimit =
        double.tryParse(_limitController.text.trim()) ?? 0;

    final outstanding =
        double.tryParse(_outstandingController.text.trim()) ?? 0;

    final creditScore =
        int.tryParse(_scoreController.text.trim()) ?? 750;

    // Validation
    if (bankName.isEmpty) {
      setState(() {
        _error = 'Please enter your bank name';
      });
      return;
    }

    if (last4.length != 4 ||
        int.tryParse(last4) == null) {
      setState(() {
        _error = 'Please enter valid last 4 card digits';
      });
      return;
    }

    if (creditLimit <= 0) {
      setState(() {
        _error = 'Please enter a valid credit limit';
      });
      return;
    }

    if (outstanding < 0) {
      setState(() {
        _error = 'Outstanding amount cannot be negative';
      });
      return;
    }

    if (outstanding > creditLimit) {
      setState(() {
        _error =
            'Outstanding amount cannot exceed credit limit';
      });
      return;
    }

    if (creditScore < 300 || creditScore > 900) {
      setState(() {
        _error = 'Credit score must be between 300 and 900';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.updateCard(
        userId: widget.userId,
        bankName: bankName,
        last4: last4,
        creditLimit: creditLimit,
        outstanding: outstanding,
        creditScore: creditScore,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Colors.white60,
        ),
        hintStyle: const TextStyle(
          color: Colors.white30,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.tealAccent,
        ),
        counterText: '',
        filled: true,
        fillColor: const Color(0xFF0F0F1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.tealAccent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF00D4AA),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Set Up Your Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Add your card details to personalize your dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildField(
                        controller: _bankController,
                        label: 'Bank Name',
                        hint: 'e.g. HDFC Bank',
                        icon: Icons.account_balance_outlined,
                      ),

                      const SizedBox(height: 16),

                      _buildField(
                        controller: _last4Controller,
                        label: 'Last 4 Card Digits',
                        hint: '1234',
                        icon: Icons.credit_card_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                      ),

                      const SizedBox(height: 16),

                      _buildField(
                        controller: _limitController,
                        label: 'Credit Limit',
                        hint: 'e.g. 100000',
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildField(
                        controller: _outstandingController,
                        label: 'Current Outstanding',
                        hint: 'e.g. 25000',
                        icon: Icons.payments_outlined,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildField(
                        controller: _scoreController,
                        label: 'Credit Score',
                        hint: '750',
                        icon: Icons.star_outline,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              _loading ? null : _saveCard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue to Dashboard',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'You can edit these details anytime later.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}