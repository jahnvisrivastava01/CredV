import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _api = ApiService();

  // Current logged-in user
  int get _userId => UserSession.instance.userId!;

  List<Transaction> _txns = [];

  bool _loading = true;

  String? _error;

  Timer? _poller;

  @override
  void initState() {
    super.initState();

    _load();

    // Refresh rewards automatically
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

  // ============================================================
  // LOAD USER TRANSACTIONS
  // ============================================================

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }

    try {
      // Fetch transactions ONLY for logged-in user
      final txns = await _api.fetchTransactions( userId: _userId,);

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
        _error = 'Could not reach the backend. Is it running? ($e)';
      });
    }
  }

  // ============================================================
  // CATEGORY ICON
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.tealAccent,
        ),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
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
            ),
          ],
        ),
      );
    }

    // Total reward coins for current user
    final totalCoins =
        _txns.fold<int>(0, (sum, t) => sum + t.rewardCoins);

    // Last 8 transactions for chart
    final chartTxns =
        _txns.take(8).toList().reversed.toList();

    return RefreshIndicator(
      color: Colors.tealAccent,
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ========================================================
          // TITLE
          // ========================================================

          const Text(
            'Rewards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ========================================================
          // TOTAL COINS CARD
          // ========================================================

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.teal,
                  Colors.tealAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 38,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Total Reward Coins',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$totalCoins 🪙',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Earn 5 coins for every ₹100 spent',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ========================================================
          // CHART TITLE
          // ========================================================

          const Text(
            'Coins earned per transaction',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // ========================================================
          // REWARDS CHART
          // ========================================================

          SizedBox(
            height: 200,
            child: chartTxns.isEmpty
                ? const Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,

                      barGroups: [
                        for (
                          int i = 0;
                          i < chartTxns.length;
                          i++
                        )
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: chartTxns[i]
                                    .rewardCoins
                                    .toDouble(),
                                color: Colors.tealAccent,
                                width: 14,
                                borderRadius:
                                    BorderRadius.circular(5),
                              ),
                            ],
                          ),
                      ],

                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false),
                        ),

                        rightTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false),
                        ),

                        bottomTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false),
                        ),

                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Colors.white10,
                            strokeWidth: 1,
                          );
                        },
                      ),

                      borderData: FlBorderData(
                        show: false,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 28),

          // ========================================================
          // RECENT REWARDS TITLE
          // ========================================================

          const Text(
            'Recent Rewards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // ========================================================
          // EMPTY STATE
          // ========================================================

          if (_txns.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    color: Colors.white38,
                    size: 40,
                  ),

                  SizedBox(height: 10),

                  Text(
                    'No rewards yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Add transactions to start earning coins!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // ========================================================
          // RECENT REWARD TRANSACTIONS
          // ========================================================

          ..._txns.take(5).map(
            (txn) => Container(
              margin: const EdgeInsets.only(bottom: 10),

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Colors.tealAccent.withOpacity(0.15),

                    child: Icon(
                      _categoryIcon(txn.category),
                      color: Colors.tealAccent,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.merchant,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '₹${txn.amount.toStringAsFixed(0)} spent',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.tealAccent.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${txn.rewardCoins} 🪙',
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}