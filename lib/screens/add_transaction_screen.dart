import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();

  final _api = ApiService();

  TxnCategory _selectedCategory = TxnCategory.food;

  bool _submitting = false;

  // Current logged-in user
  int get _userId => UserSession.instance.userId!;

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      await _api.addTransaction(
        userId: _userId,
        merchant: _merchantController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _selectedCategory.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),

      appBar: AppBar(
        backgroundColor: const Color(0xFF101114),
        elevation: 0,
        title: const Text('Add Transaction'),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Record a new expense',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 32),

                // MERCHANT NAME
                TextFormField(
                  controller: _merchantController,

                  style: const TextStyle(
                    color: Colors.white,
                  ),

                  decoration: InputDecoration(
                    labelText: 'Merchant Name',

                    prefixIcon: const Icon(
                      Icons.store,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter merchant name';
                    }

                    if (value.trim().length < 2) {
                      return 'Merchant name is too short';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // AMOUNT
                TextFormField(
                  controller: _amountController,

                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  style: const TextStyle(
                    color: Colors.white,
                  ),

                  decoration: InputDecoration(
                    labelText: 'Amount',

                    prefixText: '₹ ',

                    prefixStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter amount';
                    }

                    final amount = double.tryParse(value);

                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // CATEGORY
                DropdownButtonFormField<TxnCategory>(
                  value: _selectedCategory,

                  dropdownColor: const Color(0xFF1B1C20),

                  decoration: InputDecoration(
                    labelText: 'Category',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  items: TxnCategory.values.map((category) {
                    return DropdownMenuItem<TxnCategory>(
                      value: category,

                      child: Text(
                        category.name.toUpperCase(),

                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),

                const Spacer(),

                // ADD BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,

                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    child: _submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Add Transaction',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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