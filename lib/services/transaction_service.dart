import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'database_helper.dart';

class TransactionService {
  static const _spKey = 'transactions';
  static const _legacyKey = 'expenses';
  static const _migratedKey = 'migrated_to_sqlite';

  final _dbHelper = DatabaseHelper();

  // ── Migration from SharedPreferences ──

  Future<void> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final db = await _dbHelper.database;

    // Migrate legacy expenses first
    final legacy = prefs.getStringList(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      for (final e in legacy) {
        final json = jsonDecode(e) as Map<String, dynamic>;
        final txn = Transaction.fromLegacyJson(json);
        await db.insert('transactions', txn.toMap());
      }
      await prefs.remove(_legacyKey);
    }

    // Migrate existing transactions
    final data = prefs.getStringList(_spKey);
    if (data != null && data.isNotEmpty) {
      for (final e in data) {
        final json = jsonDecode(e) as Map<String, dynamic>;
        final txn = Transaction.fromJson(json);
        await db.insert('transactions', txn.toMap());
      }
      await prefs.remove(_spKey);
    }

    await prefs.setBool(_migratedKey, true);
  }

  // ── CRUD ──

  Future<List<Transaction>> loadTransactions() async {
    await _migrateIfNeeded();
    final db = await _dbHelper.database;
    final rows = await db.query('transactions', orderBy: 'dateTime DESC');
    return rows.map((r) => Transaction.fromMap(r)).toList();
  }

  Future<Transaction> saveTransaction(Transaction txn) async {
    final db = await _dbHelper.database;
    final id = await db.insert('transactions', txn.toMap());
    return txn.copyWithId(id);
  }

  Future<void> updateTransaction(int id, Transaction updated) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Filtering ──

  List<Transaction> getTodayTransactions(List<Transaction> all) {
    final now = DateTime.now();
    return all
        .where((t) =>
            t.dateTime.year == now.year &&
            t.dateTime.month == now.month &&
            t.dateTime.day == now.day)
        .toList();
  }

  List<Transaction> getMonthTransactions(List<Transaction> all) {
    final now = DateTime.now();
    return all
        .where((t) =>
            t.dateTime.year == now.year && t.dateTime.month == now.month)
        .toList();
  }

  List<Transaction> getExpenses(List<Transaction> all) =>
      all.where((t) => t.isExpense).toList();

  List<Transaction> getIncomes(List<Transaction> all) =>
      all.where((t) => t.isIncome).toList();

  List<Transaction> getBillPayments(List<Transaction> all) =>
      all.where((t) => t.isBillPayment).toList();

  // ── Totals ──

  double getTotal(List<Transaction> txns) =>
      txns.fold(0.0, (sum, t) => sum + t.amount);

  double getExpenseTotal(List<Transaction> all) =>
      getTotal(getExpenses(all));

  double getIncomeTotal(List<Transaction> all) =>
      getTotal(getIncomes(all));

  // ── Balance Calculations ──

  double getBankBalance(List<Transaction> all) {
    double balance = 0;
    for (final t in all) {
      if (t.isIncome) {
        balance += t.amount;
      } else if (t.isExpense && t.paidVia == PaidVia.bank) {
        balance -= t.amount;
      } else if (t.isBillPayment) {
        balance -= t.amount;
      }
    }
    return balance;
  }

  double getCreditCardOutstanding(List<Transaction> all) {
    double outstanding = 0;
    for (final t in all) {
      if (t.isExpense && t.paidVia == PaidVia.creditCard) {
        outstanding += t.amount;
      } else if (t.isBillPayment) {
        outstanding -= t.amount;
      }
    }
    return outstanding < 0 ? 0 : outstanding;
  }
}
