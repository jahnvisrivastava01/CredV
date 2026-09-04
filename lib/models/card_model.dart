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
      bankName: json['bankName']?.toString() ?? 'My Credit Card',

      last4: json['last4']?.toString() ?? '0000',

      creditLimit:
          (json['creditLimit'] as num?)?.toDouble() ?? 0.0,

      outstanding:
          (json['outstanding'] as num?)?.toDouble() ?? 0.0,

      // Backend may not return billDueDate
      billDueDate: json['billDueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((json['billDueDate'] as num).toInt()) * 1000,
            )
          : DateTime.now().add(const Duration(days: 30)),

      creditScore:
          (json['creditScore'] as num?)?.toInt() ?? 750,
    );
  }

  double get utilization =>
      creditLimit > 0 ? outstanding / creditLimit : 0;

  double get available => creditLimit - outstanding;
}