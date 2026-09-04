import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  final ApiService _api = ApiService();

  int get _userId => UserSession.instance.userId!;

  List<Transaction> _txns = [];

  bool _loading = true;
  String? _error;
  Timer? _poller;

  @override
  void initState() {
    super.initState();

    _load();

    _poller = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }

    try {
      final txns = await _api.fetchTransactions(_userId);

      if (!mounted) return;

      setState(() {
        _txns = txns;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load insights.\n$e';
      });
    }
  }

  // ============================================================
  // CATEGORY COLORS
  // ============================================================

  Color _categoryColor(TxnCategory category) {
    switch (category) {
      case TxnCategory.food:
        return Colors.orangeAccent;
      case TxnCategory.shopping:
        return Colors.purpleAccent;
      case TxnCategory.travel:
        return Colors.lightBlueAccent;
      case TxnCategory.bills:
        return Colors.pinkAccent;
      case TxnCategory.entertainment:
        return Colors.greenAccent;
      case TxnCategory.other:
        return Colors.blueGrey;
    }
  }

  // ============================================================
  // CATEGORY ICONS
  // ============================================================

  IconData _categoryIcon(TxnCategory category) {
    switch (category) {
      case TxnCategory.food:
        return Icons.restaurant;
      case TxnCategory.shopping:
        return Icons.shopping_bag;
      case TxnCategory.travel:
        return Icons.flight;
      case TxnCategory.bills:
        return Icons.receipt_long;
      case TxnCategory.entertainment:
        return Icons.movie;
      case TxnCategory.other:
        return Icons.more_horiz;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
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
          foregroundColor: Colors.white,
          title: const Text('Spending Insights'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ),
      );
    }

    // ============================================================
    // CALCULATIONS
    // ============================================================

    final categoryTotals = <TxnCategory, double>{};

    for (final txn in _txns) {
      categoryTotals[txn.category] =
          (categoryTotals[txn.category] ?? 0) + txn.amount;
    }

    final totalSpent = _txns.fold<double>(
      0,
      (sum, txn) => sum + txn.amount,
    );

    final averageSpent =
        _txns.isEmpty ? 0 : totalSpent / _txns.length;

    TxnCategory? highestCategory;

    if (categoryTotals.isNotEmpty) {
      highestCategory = categoryTotals.entries
          .reduce(
            (a, b) => a.value > b.value ? a : b,
          )
          .key;
    }

    // Sort categories from highest spending to lowest
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Spending Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: Colors.tealAccent,
        onRefresh: _load,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            // ====================================================
            // HEADER
            // ====================================================

            const Text(
              'Your spending at a glance',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // TOTAL + AVERAGE
            // ====================================================

            Row(
              children: [
                Expanded(
                  child: _InsightCard(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.tealAccent,
                    label: 'Total Spent',
                    value: '₹${totalSpent.toStringAsFixed(0)}',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _InsightCard(
                    icon: Icons.analytics_outlined,
                    iconColor: Colors.purpleAccent,
                    label: 'Average',
                    value: '₹${averageSpent.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ====================================================
            // TRANSACTIONS COUNT
            // ====================================================

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
              ),

              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.orangeAccent,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Activity recorded',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '${_txns.length}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ====================================================
            // DONUT CHART
            // ====================================================

            const Text(
              'Spending by Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  SizedBox(
                    height: 240,

                    child: Stack(
                      alignment: Alignment.center,

                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 65,

                            sections: sortedCategories.map((entry) {
                              final percentage = totalSpent == 0
                                  ? 0
                                  : (entry.value / totalSpent * 100);

                              return PieChartSectionData(
                                value: entry.value,
                                color: _categoryColor(entry.key),
                                radius: 75,
                                title:
                                    '${percentage.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        Column(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '₹${totalSpent.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ====================================================
            // CATEGORY BREAKDOWN
            // ====================================================

            const Text(
              'Category Breakdown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            ...sortedCategories.map(
              (entry) {
                final percentage = totalSpent == 0
                    ? 0
                    : entry.value / totalSpent * 100;

                final color = _categoryColor(entry.key);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),

                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),

                            child: Icon(
                              _categoryIcon(entry.key),
                              color: color,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              entry.key.name.toUpperCase(),

                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          Text(
                            '₹${entry.value.toStringAsFixed(0)}',

                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),

                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white10,

                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // ====================================================
            // TOP CATEGORY
            // ====================================================

            if (highestCategory != null)
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),

                  gradient: LinearGradient(
                    colors: [
                      _categoryColor(highestCategory).withOpacity(0.25),
                      const Color(0xFF1A1A2E),
                    ],
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: _categoryColor(highestCategory)
                            .withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        Icons.emoji_events,
                        color: _categoryColor(highestCategory),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Top spending category',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            highestCategory.name.toUpperCase(),

                            style: TextStyle(
                              color:
                                  _categoryColor(highestCategory),
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INSIGHT CARD
// ============================================================

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: const EdgeInsets.all(9),

            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            value,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            label,

            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}