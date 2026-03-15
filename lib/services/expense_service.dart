import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseService {
  static const _key = 'expenses';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data
        .map((e) => Expense.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExpense(Expense expense) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    data.add(jsonEncode(expense.toJson()));
    await prefs.setStringList(_key, data);
  }

  List<Expense> getTodayExpenses(List<Expense> all) {
    final now = DateTime.now();
    return all
        .where((e) =>
            e.dateTime.year == now.year &&
            e.dateTime.month == now.month &&
            e.dateTime.day == now.day)
        .toList();
  }

  List<Expense> getMonthExpenses(List<Expense> all) {
    final now = DateTime.now();
    return all
        .where((e) =>
            e.dateTime.year == now.year && e.dateTime.month == now.month)
        .toList();
  }

  double getTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
