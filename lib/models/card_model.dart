class CreditCardModel {
  final String bankName;
  final String last4;
  final double creditLimit;
  final double outstanding;
  final DateTime billDueDate;
  final int creditScore;

  const CreditCardModel({
    required this.bankName,
    required this.last4,
    required this.creditLimit,
    required this.outstanding,
    required this.billDueDate,
    required this.creditScore,
  });

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      bankName: json['bankName'] as String,
      last4: json['last4'] as String,
      creditLimit: (json['creditLimit'] as num).toDouble(),
      outstanding: (json['outstanding'] as num).toDouble(),
      billDueDate: DateTime.fromMillisecondsSinceEpoch(
        (json['billDueDate'] as int) * 1000,
      ),
      creditScore: json['creditScore'] as int,
    );
  }

  double get utilization => outstanding / creditLimit;

  double get available => creditLimit - outstanding;
}