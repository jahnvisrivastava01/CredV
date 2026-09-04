import 'dart:async';

import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../widgets/transaction_tile.dart';
import 'analytics_screen.dart';
import 'edit_card_screen.dart';

class CardDetailsScreen extends StatefulWidget {
  const CardDetailsScreen({super.key});

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  final ApiService _api = ApiService();

  int get _userId => UserSession.instance.userId!;

  CreditCardModel? _card;

  List<Transaction> _transactions = [];

  bool _loading = true;

  String? _error;

  Timer? _poller;

  @override
  void initState() {
    super.initState();

    _loadData();

    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadData(silent: true),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final card = await _api.fetchCard(_userId);

      final transactions =
          await _api.fetchTransactions(_userId);

      if (!mounted) return;

      setState(() {
        _card = card;
        _transactions = transactions;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load card details.\n$e';
      });
    }
  }

  // ============================================================
  // EDIT CARD - FULL PAGE
  // ============================================================

  Future<void> _editCard() async {
    if (_card == null) return;

    // Stop background polling while editing
    _poller?.cancel();

    final updatedCard = await Navigator.push<CreditCardModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCardScreen(
          card: _card!,
        ),
      ),
    );

    if (!mounted) return;

    // Restart polling after returning
    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadData(silent: true),
    );

    if (updatedCard != null) {
      setState(() {
        _card = updatedCard;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card details updated successfully'),
          backgroundColor: Colors.teal,
        ),
      );

      // Sync once with backend
      await _loadData(silent: true);
    }
  }

  // ============================================================
  // OPEN ANALYTICS
  // ============================================================

  Future<void> _openAnalytics() async {
    if (_card == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AnalyticsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F1A),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.tealAccent,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F1A),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = _card!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        title: const Text(
          'Card Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
       
      ),

      body: RefreshIndicator(
        color: Colors.tealAccent,
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // ====================================================
            // CARD SUMMARY
            // ====================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF312E81),
                    Color(0xFF164E63),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          card.bankName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _editCard,
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Text(
                    '•••• •••• •••• ${card.last4}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      _CardInfo(
                        label: 'Credit Limit',
                        value:
                            '₹${card.creditLimit.toStringAsFixed(0)}',
                      ),
                      _CardInfo(
                        label: 'Outstanding',
                        value:
                            '₹${card.outstanding.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // CREDIT SCORE
            // ====================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.speed,
                      color: Colors.tealAccent,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credit Score',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${card.creditScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Text(
                    _scoreLabel(card.creditScore),
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // UTILIZATION
            // ====================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Credit Utilization',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(card.utilization * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: card.utilization.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white10,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Colors.tealAccent,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Available credit: ₹${(card.creditLimit - card.outstanding).toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ====================================================
            // ANALYTICS BUTTON
            // ====================================================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _openAnalytics,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text(
                  'View Spending Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ====================================================
            // RECENT TRANSACTIONS
            // ====================================================

            const Text(
              'Recent Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white38,
                      size: 40,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: _transactions
                      .take(5)
                      .map(
                        (transaction) => TransactionTile(
                          txn: transaction,
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 800) return 'Excellent';
    if (score >= 750) return 'Very Good';
    if (score >= 700) return 'Good';
    if (score >= 650) return 'Fair';
    return 'Needs Improvement';
  }
}

// ============================================================
// CARD INFO WIDGET
// ============================================================

class _CardInfo extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}