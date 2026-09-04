import '../models/card_model.dart';
import '../models/transaction.dart';

class MockData {
  static final card = CreditCardModel(
    bankName: 'HDFC Bank',
    last4: '4821',
    creditLimit: 150000,
    outstanding: 42350,
    billDueDate: DateTime.now().add(const Duration(days: 9)),
    creditScore: 782,
  );

  static List<Transaction> transactions() {
    final now = DateTime.now();
    final raw = <Transaction>[
      Transaction(
          id: 't1',
          merchant: 'Swiggy',
          amount: 486,
          date: now.subtract(const Duration(days: 1)),
          category: TxnCategory.food,
          rewardCoins: 24),
      Transaction(
          id: 't2',
          merchant: 'Amazon',
          amount: 2399,
          date: now.subtract(const Duration(days: 2)),
          category: TxnCategory.shopping,
          rewardCoins: 120),
      Transaction(
          id: 't3',
          merchant: 'IRCTC',
          amount: 1850,
          date: now.subtract(const Duration(days: 4)),
          category: TxnCategory.travel,
          rewardCoins: 92),
      Transaction(
          id: 't4',
          merchant: 'Airtel Postpaid',
          amount: 599,
          date: now.subtract(const Duration(days: 6)),
          category: TxnCategory.bills,
          rewardCoins: 30),
      Transaction(
          id: 't5',
          merchant: 'BookMyShow',
          amount: 700,
          date: now.subtract(const Duration(days: 8)),
          category: TxnCategory.entertainment,
          rewardCoins: 35),
      Transaction(
          id: 't6',
          merchant: 'Zomato',
          amount: 320,
          date: now.subtract(const Duration(days: 10)),
          category: TxnCategory.food,
          rewardCoins: 16),
    ];
    // Sorted newest-first so it renders correctly in the transactions list.
    raw.sort((a, b) => b.date.compareTo(a.date));
    return raw;
  }
}
