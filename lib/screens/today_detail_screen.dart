import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class TodayDetailScreen extends StatefulWidget {
  final List<Expense> expenses;

  const TodayDetailScreen({super.key, required this.expenses});

  @override
  State<TodayDetailScreen> createState() => _TodayDetailScreenState();
}

class _TodayDetailScreenState extends State<TodayDetailScreen> {
  final _service = ExpenseService();
  late List<Expense> _expenses;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _expenses = List<Expense>.from(widget.expenses);
  }

  Future<void> _reload() async {
    final all = await _service.loadExpenses();
    setState(() {
      _expenses = _service.getTodayExpenses(all);
    });
  }

  void _showEditDialog(Expense expense) {
    final labelCtrl = TextEditingController(text: expense.label);
    final amountCtrl = TextEditingController(text: expense.amount.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Expense',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              TextFormField(
                controller: labelCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Label', Icons.label_outline_rounded),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter label' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Amount', Icons.currency_rupee_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount';
                  if (double.tryParse(v.trim()) == null) return 'Invalid number';
                  if (double.parse(v.trim()) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _deleteExpense(expense);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        await _updateExpense(
                          expense,
                          labelCtrl.text.trim(),
                          double.parse(amountCtrl.text.trim()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateExpense(Expense old, String newLabel, double newAmount) async {
    final all = await _service.loadExpenses();
    final idx = _service.findExpenseIndex(all, old);
    if (idx == -1) return;
    final updated = Expense(label: newLabel, amount: newAmount, dateTime: old.dateTime);
    await _service.updateExpense(idx, updated);
    _changed = true;
    await _reload();
  }

  Future<void> _deleteExpense(Expense expense) async {
    final all = await _service.loadExpenses();
    final idx = _service.findExpenseIndex(all, expense);
    if (idx == -1) return;
    await _service.deleteExpense(idx);
    _changed = true;
    await _reload();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
      filled: true,
      fillColor: const Color(0xFF0F0F1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Expense>.from(_expenses)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final total = _service.getTotal(_expenses);
    final today = DateFormat('EEEE, dd MMMM').format(DateTime.now());

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _changed) {
          // Signal home screen to reload
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          title: Text(today,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A1A2E),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: sorted.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 64, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    Text('No expenses today',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.white.withOpacity(0.06), height: 1),
                      itemBuilder: (context, index) {
                        final e = sorted[index];
                        return GestureDetector(
                          onTap: () => _showEditDialog(e),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat('hh:mm a').format(e.dateTime),
                                      style: const TextStyle(
                                        color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(e.label,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(e.amount),
                                  style: const TextStyle(
                                      color: Color(0xFFFF6B6B), fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
