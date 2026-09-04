enum TxnCategory { food, shopping, travel, bills, entertainment, other }

class Transaction {
  final String id;
  final String merchant;
  final double amount;
  final DateTime date;
  final TxnCategory category;
  final int rewardCoins;

  const Transaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.rewardCoins,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String).toLocal(),
      category: TxnCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => TxnCategory.other,
      ),
      rewardCoins: json['rewardCoins'] as int,
    );
  }
}
