import 'package:flutter/material.dart';

/// Types of transactions in the app
enum TransactionType { expense, income, billPayment }

/// Payment source for expenses
enum PaidVia { bank, creditCard }

/// Expense categories
enum ExpenseCategory {
  food,
  vehicle,
  fuel,
  clothes,
  groceries,
  loan,
  savings,
  investments,
  other;

  String get label {
    switch (this) {
      case food: return 'Food';
      case vehicle: return 'Vehicle';
      case fuel: return 'Fuel';
      case clothes: return 'Clothes';
      case groceries: return 'Groceries';
      case loan: return 'Loan';
      case savings: return 'Savings';
      case investments: return 'Investments';
      case other: return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case food: return Icons.restaurant_rounded;
      case vehicle: return Icons.directions_car_rounded;
      case fuel: return Icons.local_gas_station_rounded;
      case clothes: return Icons.checkroom_rounded;
      case groceries: return Icons.shopping_cart_rounded;
      case loan: return Icons.account_balance_rounded;
      case savings: return Icons.savings_rounded;
      case investments: return Icons.trending_up_rounded;
      case other: return Icons.more_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case food: return const Color(0xFFFF6B6B);
      case vehicle: return const Color(0xFF6C63FF);
      case fuel: return const Color(0xFFE67E22);
      case clothes: return const Color(0xFFE91E63);
      case groceries: return const Color(0xFF2ECC71);
      case loan: return const Color(0xFF00BCD4);
      case savings: return const Color(0xFFFFCA28);
      case investments: return const Color(0xFF26A69A);
      case other: return const Color(0xFF78909C);
    }
  }
}

class Transaction {
  final int? id;
  final String label;
  final double amount;
  final DateTime dateTime;
  final TransactionType type;
  final PaidVia? paidVia; // only for expenses
  final ExpenseCategory? category; // only for expenses

  Transaction({
    this.id,
    required this.label,
    required this.amount,
    required this.dateTime,
    required this.type,
    this.paidVia,
    this.category,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isBillPayment => type == TransactionType.billPayment;

  /// Copy with a new id (used after DB insert)
  Transaction copyWithId(int newId) => Transaction(
        id: newId,
        label: label,
        amount: amount,
        dateTime: dateTime,
        type: type,
        paidVia: paidVia,
        category: category,
      );

  // ── SQLite Map ──

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'label': label,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'type': type.name,
        'paidVia': paidVia?.name,
        'category': category?.name,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String?;
    final paidViaStr = map['paidVia'] as String?;
    final catStr = map['category'] as String?;

    return Transaction(
      id: map['id'] as int?,
      label: map['label'] as String,
      amount: (map['amount'] as num).toDouble(),
      dateTime: DateTime.parse(map['dateTime'] as String),
      type: typeStr != null
          ? TransactionType.values.firstWhere((e) => e.name == typeStr,
              orElse: () => TransactionType.expense)
          : TransactionType.expense,
      paidVia: paidViaStr != null
          ? PaidVia.values.firstWhere((e) => e.name == paidViaStr,
              orElse: () => PaidVia.bank)
          : null,
      category: catStr != null
          ? ExpenseCategory.values.firstWhere((e) => e.name == catStr,
              orElse: () => ExpenseCategory.other)
          : null,
    );
  }

  // ── JSON (kept for SharedPreferences migration) ──

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'type': type.name,
        'paidVia': paidVia?.name,
        'category': category?.name,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final paidViaStr = json['paidVia'] as String?;
    final catStr = json['category'] as String?;

    return Transaction(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: typeStr != null
          ? TransactionType.values.firstWhere((e) => e.name == typeStr,
              orElse: () => TransactionType.expense)
          : TransactionType.expense,
      paidVia: paidViaStr != null
          ? PaidVia.values.firstWhere((e) => e.name == paidViaStr,
              orElse: () => PaidVia.bank)
          : null,
      category: catStr != null
          ? ExpenseCategory.values.firstWhere((e) => e.name == catStr,
              orElse: () => ExpenseCategory.other)
          : null,
    );
  }

  /// Migrate a legacy expense JSON (no type field) into a Transaction
  factory Transaction.fromLegacyJson(Map<String, dynamic> json) {
    return Transaction(
      label: json['label'] as String,
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      type: TransactionType.expense,
      paidVia: PaidVia.bank,
      category: ExpenseCategory.other,
    );
  }
}
