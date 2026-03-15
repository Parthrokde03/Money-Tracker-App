import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class MonthDetailScreen extends StatelessWidget {
  final List<Expense> expenses;
  final String monthLabel;

  const MonthDetailScreen({
    super.key,
    required this.expenses,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = ExpenseService().getTotal(expenses);

    // Group expenses by day
    final Map<String, List<Expense>> grouped = {};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.dateTime);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    // Sort days descending
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: Text(monthLabel,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 64, color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  Text('No expenses this month',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: sortedKeys.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.white.withOpacity(0.06), height: 1),
                    itemBuilder: (context, index) {
                      final dayExpenses = grouped[sortedKeys[index]]!;
                      final date = dayExpenses.first.dateTime;
                      final dayTotal = ExpenseService().getTotal(dayExpenses);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Column(
                                children: [
                                  Text(DateFormat('dd').format(date),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                                  Text(DateFormat('MMM').format(date),
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('EEEE').format(date),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 3),
                                  Text('${dayExpenses.length} expense${dayExpenses.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(dayTotal),
                              style: const TextStyle(
                                  color: Color(0xFFFF6B6B), fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A2E),
                    border: Border(top: BorderSide(color: Color(0xFF2A2A3E))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(
                        NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(total),
                        style: const TextStyle(
                            color: Color(0xFF6C63FF), fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
