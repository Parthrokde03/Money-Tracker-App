import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class BudgetService extends ChangeNotifier {
  static final BudgetService _instance = BudgetService._();
  factory BudgetService() => _instance;
  BudgetService._();

  static const _overallKey = 'budget_overall';
  static const _categoryKey = 'budget_categories';
  static const _enabledKey = 'budget_enabled';

  bool _enabled = false;
  double _overallBudget = 0;
  Map<ExpenseCategory, double> _categoryBudgets = {};

  bool get isEnabled => _enabled;
  double get overallBudget => _overallBudget;
  Map<ExpenseCategory, double> get categoryBudgets => Map.unmodifiable(_categoryBudgets);
  bool get hasOverallBudget => _overallBudget > 0;
  bool get hasCategoryBudgets => _categoryBudgets.isNotEmpty;
  bool get hasBudget => _enabled && (hasOverallBudget || hasCategoryBudgets);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _overallBudget = prefs.getDouble(_overallKey) ?? 0;
    final catJson = prefs.getString(_categoryKey);
    if (catJson != null) {
      final map = jsonDecode(catJson) as Map<String, dynamic>;
      _categoryBudgets = {};
      for (final e in map.entries) {
        final cat = ExpenseCategory.values.where((c) => c.name == e.key).firstOrNull;
        if (cat != null && (e.value as num).toDouble() > 0) {
          _categoryBudgets[cat] = (e.value as num).toDouble();
        }
      }
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  Future<void> setOverallBudget(double amount) async {
    _overallBudget = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_overallKey, amount);
    notifyListeners();
  }

  Future<void> setCategoryBudget(ExpenseCategory cat, double amount) async {
    if (amount <= 0) {
      _categoryBudgets.remove(cat);
    } else {
      _categoryBudgets[cat] = amount;
    }
    await _saveCategoryBudgets();
    notifyListeners();
  }

  Future<void> removeCategoryBudget(ExpenseCategory cat) async {
    _categoryBudgets.remove(cat);
    await _saveCategoryBudgets();
    notifyListeners();
  }

  Future<void> _saveCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, double>{};
    for (final e in _categoryBudgets.entries) {
      map[e.key.name] = e.value;
    }
    await prefs.setString(_categoryKey, jsonEncode(map));
  }

  /// Get spending percentage (0.0 to 1.0+) for overall budget.
  double getOverallProgress(double monthExpenseTotal) {
    if (_overallBudget <= 0) return 0;
    return monthExpenseTotal / _overallBudget;
  }

  /// Get spending percentage for a category.
  double getCategoryProgress(ExpenseCategory cat, double catSpent) {
    final budget = _categoryBudgets[cat];
    if (budget == null || budget <= 0) return 0;
    return catSpent / budget;
  }

  /// Get alert level: 0 = ok, 1 = warning (>=80%), 2 = over (>=100%).
  int alertLevel(double progress) {
    if (progress >= 1.0) return 2;
    if (progress >= 0.8) return 1;
    return 0;
  }
}
