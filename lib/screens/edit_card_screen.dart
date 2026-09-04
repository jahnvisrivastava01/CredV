import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_model.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class EditCardScreen extends StatefulWidget {
  final CreditCardModel card;

  const EditCardScreen({
    super.key,
    required this.card,
  });

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  final ApiService _api = ApiService();

  // Logged-in user ID
  int get _userId => UserSession.instance.userId!;

  late final TextEditingController _bankNameController;
  late final TextEditingController _last4Controller;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _outstandingController;
  late final TextEditingController _creditScoreController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _bankNameController = TextEditingController(
      text: widget.card.bankName,
    );

    _last4Controller = TextEditingController(
      text: widget.card.last4,
    );

    _creditLimitController = TextEditingController(
      text: widget.card.creditLimit.toStringAsFixed(0),
    );

    _outstandingController = TextEditingController(
      text: widget.card.outstanding.toStringAsFixed(0),
    );

    _creditScoreController = TextEditingController(
      text: widget.card.creditScore.toString(),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _last4Controller.dispose();
    _creditLimitController.dispose();
    _outstandingController.dispose();
    _creditScoreController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE CARD
  // ============================================================

  Future<void> _saveCard() async {
    if (_saving) return;

    final bankName = _bankNameController.text.trim();
    final last4 = _last4Controller.text.trim();

    final creditLimit = double.tryParse(
      _creditLimitController.text.trim(),
    );

    final outstanding = double.tryParse(
      _outstandingController.text.trim(),
    );

    final creditScore = int.tryParse(
      _creditScoreController.text.trim(),
    );

    // ============================================================
    // VALIDATION
    // ============================================================

    if (bankName.isEmpty) {
      _showError('Please enter bank name');
      return;
    }

    if (last4.length != 4 || int.tryParse(last4) == null) {
      _showError('Last 4 digits must contain exactly 4 numbers');
      return;
    }

    if (creditLimit == null || creditLimit <= 0) {
      _showError('Please enter a valid credit limit');
      return;
    }

    if (outstanding == null || outstanding < 0) {
      _showError('Please enter a valid outstanding amount');
      return;
    }

    if (outstanding > creditLimit) {
      _showError(
        'Outstanding amount cannot exceed credit limit',
      );
      return;
    }

    if (creditScore == null ||
        creditScore < 300 ||
        creditScore > 900) {
      _showError(
        'Credit score must be between 300 and 900',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      // ============================================================
      // UPDATE CARD WITH USER ID
      // ============================================================

      final updatedCard = await _api.updateCard(
        userId: _userId,
        bankName: bankName,
        last4: last4,
        creditLimit: creditLimit,
        outstanding: outstanding,
        creditScore: creditScore,
      );

      if (!mounted) return;

      Navigator.pop(context, updatedCard);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(
        'Failed to update card: $e',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: const Text(
          'Edit Card',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.of(context).viewInsets.bottom + 30,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update your card information',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 28),

              // ====================================================
              // BANK NAME
              // ====================================================

              _buildField(
                controller: _bankNameController,
                label: 'Bank Name',
                hint: 'e.g. State Bank of India',
                icon: Icons.account_balance_outlined,
                capitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 18),

              // ====================================================
              // LAST 4 DIGITS
              // ====================================================

              _buildField(
                controller: _last4Controller,
                label: 'Last 4 Digits',
                hint: 'e.g. 4821',
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),

              const SizedBox(height: 18),

              // ====================================================
              // CREDIT LIMIT
              // ====================================================

              _buildField(
                controller: _creditLimitController,
                label: 'Credit Limit',
                hint: 'e.g. 150000',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixText: '₹ ',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ====================================================
              // OUTSTANDING BALANCE
              // ====================================================

              _buildField(
                controller: _outstandingController,
                label: 'Outstanding Balance',
                hint: 'e.g. 42350',
                icon: Icons.payments_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixText: '₹ ',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ====================================================
              // CREDIT SCORE
              // ====================================================

              _buildField(
                controller: _creditScoreController,
                label: 'Credit Score',
                hint: '300 - 900',
                icon: Icons.speed_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),

              const SizedBox(height: 32),

              // ====================================================
              // SAVE BUTTON
              // ====================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveCard,

                  icon: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),

                  label: Text(
                    _saving
                        ? 'Saving Changes...'
                        : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.teal.withOpacity(0.5),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REUSABLE INPUT FIELD
  // ============================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization =
        TextCapitalization.none,
    int? maxLength,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLength: maxLength,
      inputFormatters: inputFormatters,

      style: const TextStyle(
        color: Colors.white,
      ),

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: Colors.tealAccent,
        ),

        prefixText: prefixText,

        floatingLabelBehavior:
            FloatingLabelBehavior.always,

        labelStyle: const TextStyle(
          color: Colors.tealAccent,
          fontSize: 14,
        ),

        hintStyle: const TextStyle(
          color: Colors.white30,
        ),

        prefixStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),

        counterStyle: const TextStyle(
          color: Colors.white38,
        ),

        filled: true,
        fillColor: const Color(0xFF1A1A2E),

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.white12,
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