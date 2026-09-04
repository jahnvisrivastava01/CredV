import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _api = ApiService();

  List<Transaction> _transactions = [];
  bool _loading = true;
  String? _error;

  String _selectedCategory = 'All';

  int get _userId => UserSession.instance.userId!;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // ============================================================
  // LOAD TRANSACTIONS
  // ============================================================

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final transactions = await _api.fetchTransactions(_userId);

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // FILTERED TRANSACTIONS
  // ============================================================

  List<Transaction> get _filteredTransactions {
    if (_selectedCategory == 'All') {
      return _transactions;
    }

    return _transactions.where((transaction) {
      return transaction.category.name.toLowerCase() ==
          _selectedCategory.toLowerCase();
    }).toList();
  }

  // ============================================================
  // CATEGORY ICON
  // ============================================================

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;

      case 'shopping':
        return Icons.shopping_bag;

      case 'travel':
        return Icons.flight;

      case 'bills':
        return Icons.receipt_long;

      case 'entertainment':
        return Icons.movie;

      case 'other':
        return Icons.more_horiz;

      default:
        return Icons.category;
    }
  }

  // ============================================================
  // CATEGORY COLOR
  // ============================================================

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orangeAccent;

      case 'shopping':
        return Colors.purpleAccent;

      case 'travel':
        return Colors.blueAccent;

      case 'bills':
        return Colors.redAccent;

      case 'entertainment':
        return Colors.pinkAccent;

      case 'other':
        return Colors.tealAccent;

      default:
        return Colors.tealAccent;
    }
  }

  // ============================================================
  // ADD TRANSACTION
  // ============================================================

  Future<void> _addTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadTransactions();
    }
  }

  // ============================================================
  // EDIT TRANSACTION
  // ============================================================

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTransactionScreen(
          transaction: transaction,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadTransactions();
    }
  }

  // ============================================================
  // DELETE TRANSACTION
  // ============================================================

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Transaction?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the transaction from ${transaction.merchant}?',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteTransaction(
        userId: _userId,
        id: transaction.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: Colors.teal,
        ),
      );

      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete transaction: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // CATEGORY FILTER CHIP
  // ============================================================

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != 'All') ...[
              Icon(
                _categoryIcon(category),
                size: 16,
                color: isSelected
                    ? Colors.black
                    : _categoryColor(category),
              ),
              const SizedBox(width: 6),
            ],
            Text(category),
          ],
        ),
        selectedColor: Colors.tealAccent,
        backgroundColor: const Color(0xFF1A1A2E),
        side: BorderSide(
          color: isSelected
              ? Colors.tealAccent
              : Colors.white.withOpacity(0.12),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTransaction,
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Transaction',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.tealAccent,
                ),
              )
            : _error != null
                ? _buildError()
                : _buildTransactions(),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRANSACTION LIST
  // ============================================================

  Widget _buildTransactions() {
    if (_transactions.isEmpty) {
      return RefreshIndicator(
        color: Colors.tealAccent,
        onRefresh: _loadTransactions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: const [
            SizedBox(height: 100),
            Icon(
              Icons.receipt_long_outlined,
              color: Colors.white24,
              size: 70,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Start tracking your spending by adding a transaction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredTransactions = _filteredTransactions;

    final totalSpent = filteredTransactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );

    return RefreshIndicator(
      color: Colors.tealAccent,
      onRefresh: _loadTransactions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          100,
        ),
        children: [
          // ======================================================
          // TITLE
          // ======================================================

          const Text(
            'Transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // TOTAL SPENT CARD
          // ======================================================

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.teal.withOpacity(0.8),
                  Colors.tealAccent.withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCategory == 'All'
                            ? 'Total Spent'
                            : '${_selectedCategory} Spending',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '₹${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // CATEGORY FILTERS
          // ======================================================

          const Text(
            'Filter by category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All'),
                _buildCategoryChip('Food'),
                _buildCategoryChip('Shopping'),
                _buildCategoryChip('Travel'),
                _buildCategoryChip('Bills'),
                _buildCategoryChip('Entertainment'),
                _buildCategoryChip('Other'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ======================================================
          // TRANSACTION COUNT
          // ======================================================

          Text(
            _selectedCategory == 'All'
                ? 'Recent Transactions'
                : '${_selectedCategory} Transactions',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // EMPTY FILTER STATE
          // ======================================================

          if (filteredTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 40,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    _categoryIcon(_selectedCategory),
                    color: Colors.white24,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No ${_selectedCategory.toLowerCase()} transactions',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

          // ======================================================
          // TRANSACTION TILES
          // ======================================================

          ...filteredTransactions.map(
            (transaction) => Card(
              color: const Color(0xFF1A1A2E),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: TransactionTile(
                txn: transaction,

                // 3 DOTS → EDIT
                onEdit: () => _editTransaction(transaction),

                // 3 DOTS → DELETE
                onDelete: () => _deleteTransaction(transaction),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}