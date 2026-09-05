import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/user_session.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/transaction_tile.dart';

import 'transactions_screen.dart';

import 'rewards_screen.dart';
import 'emi_calculator_screen.dart';
import 'profile_screen.dart';
import 'card_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const TransactionsScreen(),
      const RewardsScreen(),
      const EmiCalculatorScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() {
            _tab = index;
          });
        },
        indicatorColor: Colors.tealAccent.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'EMI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME TAB
// ============================================================

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ApiService _api = ApiService();

  CreditCardModel? _card;
  List<Transaction> _transactions = [];

  bool _loading = true;
  String? _error;

  int get _userId {
    final id = UserSession.instance.userId;

    if (id == null) {
      throw Exception('User is not logged in');
    }

    return id;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.fetchCard(
          userId: _userId,
        ),
        _api.fetchTransactions(
          userId: _userId,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _card = results[0] as CreditCardModel;
        _transactions = results[1] as List<Transaction>;
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
  // GREETING
  // ============================================================

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // ============================================================
  // OPEN CARD DETAILS
  // ============================================================

  Future<void> _openCardDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CardDetailsScreen(),
      ),
    );

    // Refresh card after returning from edit/card details
    if (mounted) {
      _loadDashboard();
    }
  }

  // ============================================================
  // TOTAL SPENT
  // ============================================================

  double get _totalSpent {
    return _transactions.fold<double>(
      0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  // ============================================================
  // TOTAL REWARD COINS
  // ============================================================

  int get _totalCoins {
    return _transactions.fold<int>(
      0,
      (sum, transaction) => sum + transaction.rewardCoins,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // LOADING
    // ============================================================

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.tealAccent,
        ),
      );
    }

    // ============================================================
    // ERROR
    // ============================================================

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                color: Colors.white54,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Could not load dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final card = _card;

    // ============================================================
    // USER NAME
    // ============================================================

    final userName = UserSession.instance.name?.trim().isNotEmpty == true
        ? UserSession.instance.name!
        : 'User';

    final recentTransactions = _transactions.take(5).toList();

    // ============================================================
    // MAIN HOME
    // ============================================================

    return RefreshIndicator(
      color: Colors.tealAccent,
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          30,
        ),
        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Text(
            '${_greeting()} 👋',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // ========================================================
          // CREDIT CARD
          // CLICKABLE → CARD DETAILS
          // ========================================================

          if (card != null)
            GestureDetector(
              onTap: _openCardDetails,
              child: CreditCardWidget(
                card: card,
              ),
            ),

          if (card != null) const SizedBox(height: 8),

          if (card != null)
            Center(
              child: Text(
                'Tap card to view and edit details',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.38),
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(height: 22),

          // ========================================================
          // CREDIT SCORE + UTILIZATION
          // ========================================================

          if (card != null)
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.credit_score,
                    iconColor: Colors.purpleAccent,
                    value: '${card.creditScore}',
                    label: 'Credit Score',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.pie_chart_outline,
                    iconColor: Colors.orangeAccent,
                    value: '${(card.utilization * 100).toStringAsFixed(0)}%',
                    label: 'Utilization',
                  ),
                ),
              ],
            ),

          const SizedBox(height: 28),

          // ========================================================
          // QUICK OVERVIEW TITLE
          // ========================================================

          const Text(
            'Quick Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          // ========================================================
          // QUICK OVERVIEW
          // ========================================================

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.tealAccent,
                    value: '₹${_totalSpent.toStringAsFixed(0)}',
                    label: 'Spent',
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.monetization_on_outlined,
                    iconColor: Colors.amber,
                    value: '$_totalCoins',
                    label: 'Coins',
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _OverviewItem(
                    icon: Icons.receipt_long_outlined,
                    iconColor: Colors.lightBlueAccent,
                    value: '${_transactions.length}',
                    label: 'Transactions',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ========================================================
          // RECENT TRANSACTIONS HEADER
          // ========================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_transactions.length} total',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ========================================================
          // NO TRANSACTIONS
          // ========================================================

          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white38,
                    size: 42,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Your transactions will appear here',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )

          // ========================================================
          // RECENT TRANSACTION LIST
          // ========================================================

          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < recentTransactions.length; i++) ...[
                    TransactionTile(
                      txn: recentTransactions[i],
                    ),
                    if (i != recentTransactions.length - 1)
                      const Divider(
                        color: Colors.white10,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                ],
              ),
            ),

          // ========================================================
          // BOTTOM SPACE
          // Keeps content comfortably above navigation
          // ========================================================

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ============================================================
// INFO CARD
// ============================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK OVERVIEW ITEM
// ============================================================

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _OverviewItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 23,
        ),
        const SizedBox(height: 9),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
