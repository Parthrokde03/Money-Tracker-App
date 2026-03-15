class Expense {
  final String label;
  final double amount;
  final DateTime dateTime;

  Expense({
    required this.label,
    required this.amount,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime'] as String),
      );
}
