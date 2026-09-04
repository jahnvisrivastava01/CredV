import 'dart:math';

import 'package:flutter/material.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _tenureController = TextEditingController();

  double? _emi;
  double? _totalPayment;
  double? _totalInterest;

  void _calculateEmi() {
    final principal = double.tryParse(_amountController.text.trim());
    final annualInterest = double.tryParse(_interestController.text.trim());
    final tenureYears = double.tryParse(_tenureController.text.trim());

    if (principal == null ||
        annualInterest == null ||
        tenureYears == null ||
        principal <= 0 ||
        annualInterest < 0 ||
        tenureYears <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid loan details'),
        ),
      );
      return;
    }

    final monthlyRate = annualInterest / 12 / 100;
    final months = (tenureYears * 12).round();

    final double emi;

    if (monthlyRate == 0) {
      emi = principal / months;
    } else {
      final power = pow(1 + monthlyRate, months).toDouble();

      emi = principal *
          monthlyRate *
          power /
          (power - 1);
    }

    setState(() {
      _emi = emi;
      _totalPayment = emi * months;
      _totalInterest = _totalPayment! - principal;
    });
  }

  void _reset() {
    _amountController.clear();
    _interestController.clear();
    _tenureController.clear();

    setState(() {
      _emi = null;
      _totalPayment = null;
      _totalInterest = null;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'EMI Calculator',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Plan your loan repayments easily',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 28),

            _inputField(
              controller: _amountController,
              label: 'Loan Amount',
              icon: Icons.currency_rupee,
              hint: 'e.g. 500000',
            ),

            const SizedBox(height: 16),

            _inputField(
              controller: _interestController,
              label: 'Interest Rate (%)',
              icon: Icons.percent,
              hint: 'e.g. 8.5',
              decimal: true,
            ),

            const SizedBox(height: 16),

            _inputField(
              controller: _tenureController,
              label: 'Loan Tenure (Years)',
              icon: Icons.calendar_month_outlined,
              hint: 'e.g. 5',
              decimal: true,
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _calculateEmi,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'Calculate EMI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_emi != null) _resultCard(),

            if (_emi != null)
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Calculator'),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimal,
      ),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(
          icon,
          color: Colors.tealAccent,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF2A5C58),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Your Monthly EMI',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '₹${_emi!.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          const Divider(color: Colors.white24),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _resultItem(
                'Total Interest',
                '₹${_totalInterest!.toStringAsFixed(0)}',
              ),
              _resultItem(
                'Total Payment',
                '₹${_totalPayment!.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}