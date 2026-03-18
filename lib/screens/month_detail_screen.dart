import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';

const _bg = Color(0xFF0F0F1A);
const _surface = Color(0xFF1A1A2E);
const _accent = Color(0xFF6C63FF);
const _green = Color(0xFF2ECC71);
const _red = Color(0xFFFF6B6B);
const _orange = Color(0xFFE67E22);
const _border = Color(0x0FFFFFFF);
const _muted = Color(0x99FFFFFF);
const _dimmed = Color(0x59FFFFFF);

class MonthDetailScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final String monthLabel;
  const MonthDetailScreen({super.key, required this.transactions, required this.monthLabel});
  @override
  State<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends State<MonthDetailScreen> {
  final _service = TransactionService();
  final _auth = AuthService();
  late List<Transaction> _txns;
  String? _expandedDay;

  @override
  void initState() { super.initState(); _txns = List<Transaction>.from(widget.transactions); }

  Future<void> _reload() async {
    final all = await _service.loadTransactions();
    final first = widget.transactions.isNotEmpty ? widget.transactions.first.dateTime : DateTime.now();
    setState(() { _txns = all.where((t) => t.dateTime.year == first.year && t.dateTime.month == first.month).toList(); });
  }

  String _fmt(double v) => NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(v);
  String _fmtShort(double v) {
    if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  Color _txnColor(Transaction t) { if (t.isIncome) return _green; if (t.isBillPayment) return _orange; return _red; }
  String _txnPrefix(Transaction t) => t.isIncome ? '+' : '-';

  String _txnTag(Transaction t) {
    if (t.isIncome) return 'Income';
    if (t.isBillPayment) return 'Bill Payment';
    final catLabel = t.category?.label ?? '';
    final via = t.paidVia == PaidVia.creditCard ? 'Credit Card' : 'Bank';
    return catLabel.isNotEmpty ? '$catLabel · $via' : via;
  }

  IconData _txnIcon(Transaction t) {
    if (t.isIncome) return Icons.arrow_downward_rounded;
    if (t.isBillPayment) return Icons.receipt_long_rounded;
    return t.category?.icon ?? Icons.shopping_bag_rounded;
  }

  void _showEditSheet(Transaction txn) {
    if (!_auth.isDeveloper) return;
    final labelCtrl = TextEditingController(text: txn.label);
    final amountCtrl = TextEditingController(text: txn.amount.toString());
    final formKey = GlobalKey<FormState>();
    DateTime editDate = txn.dateTime;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _dimmed, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Edit ${txn.isExpense ? "Expense" : txn.isIncome ? "Income" : "Bill Payment"}',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            TextFormField(controller: labelCtrl, style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Label', Icons.label_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter label' : null),
            const SizedBox(height: 14),
            TextFormField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Amount', Icons.currency_rupee_rounded),
              validator: (v) { if (v == null || v.trim().isEmpty) return 'Enter amount'; if (double.tryParse(v.trim()) == null) return 'Invalid number'; if (double.parse(v.trim()) <= 0) return 'Must be > 0'; return null; }),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: editDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
                  builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface)), child: child!));
                if (picked != null) setSheetState(() => editDate = DateTime(picked.year, picked.month, picked.day, txn.dateTime.hour, txn.dateTime.minute, txn.dateTime.second));
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, color: _dimmed, size: 18),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd MMM yyyy').format(editDate), style: const TextStyle(color: Colors.white, fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () async { Navigator.pop(ctx); if (txn.id == null) return; await _service.deleteTransaction(txn.id!); await _reload(); },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Delete'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return; Navigator.pop(ctx); if (txn.id == null) return;
                  await _service.updateTransaction(txn.id!, Transaction(id: txn.id, label: labelCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text.trim()), dateTime: editDate, type: txn.type, paidVia: txn.paidVia, category: txn.category));
                  await _reload();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save'))),
            ]),
          ])),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(hintText: hint, hintStyle: const TextStyle(color: _dimmed),
      prefixIcon: Icon(icon, color: _muted, size: 20), filled: true, fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)));
  }

  @override
  Widget build(BuildContext context) {
    final expenseTotal = _service.getExpenseTotal(_txns);
    final incomeTotal = _service.getIncomeTotal(_txns);

    final Map<String, List<Transaction>> grouped = {};
    for (final t in _txns) {
      final key = DateFormat('yyyy-MM-dd').format(t.dateTime);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(widget.monthLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true, backgroundColor: _surface, elevation: 0, surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: sortedKeys.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_rounded, size: 56, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 12),
              const Text('No transactions this month', style: TextStyle(color: _dimmed, fontSize: 15)),
            ]))
          : Column(children: [
              // Summary bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Row(children: [
                  if (incomeTotal > 0) ...[
                    const Icon(Icons.arrow_downward_rounded, color: _green, size: 14),
                    const SizedBox(width: 4),
                    Text(_fmtShort(incomeTotal), style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.arrow_upward_rounded, color: _red, size: 14),
                  const SizedBox(width: 4),
                  Text(_fmtShort(expenseTotal), style: const TextStyle(color: _red, fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (incomeTotal > 0)
                    Text(incomeTotal >= expenseTotal ? 'Surplus: ${_fmtShort(incomeTotal - expenseTotal)}' : 'Deficit: ${_fmtShort(expenseTotal - incomeTotal)}',
                      style: TextStyle(color: incomeTotal >= expenseTotal ? _green : _red, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final dayKey = sortedKeys[index];
                    final dayTxns = grouped[dayKey]!;
                    final date = dayTxns.first.dateTime;
                    final dayExpenses = _service.getExpenses(dayTxns);
                    final dayExpenseTotal = _service.getTotal(dayExpenses);
                    final dayIncome = _service.getIncomes(dayTxns);
                    final dayIncomeTotal = _service.getTotal(dayIncome);
                    final isExpanded = _expandedDay == dayKey;

                    return Column(children: [
                      GestureDetector(
                        onTap: () => setState(() { _expandedDay = isExpanded ? null : dayKey; }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(children: [
                            // Date block
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(DateFormat('dd').format(date), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                Text(DateFormat('MMM').format(date), style: const TextStyle(color: _dimmed, fontSize: 9)),
                              ]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(DateFormat('EEEE').format(date), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text('${dayTxns.length} transaction${dayTxns.length > 1 ? 's' : ''}', style: const TextStyle(color: _dimmed, fontSize: 11)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              if (dayExpenseTotal > 0)
                                Text('-${_fmtShort(dayExpenseTotal)}', style: const TextStyle(color: _red, fontSize: 14, fontWeight: FontWeight.w700)),
                              if (dayIncomeTotal > 0)
                                Text('+${_fmtShort(dayIncomeTotal)}', style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.expand_more_rounded, color: _dimmed, size: 18),
                            ),
                          ]),
                        ),
                      ),
                      // Expanded transactions
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                          child: Column(children: dayTxns.map((t) => GestureDetector(
                            onTap: _auth.isDeveloper ? () => _showEditSheet(t) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(color: _txnColor(t).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(_txnIcon(t), color: _txnColor(t), size: 14),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                                  Text(_txnTag(t), style: const TextStyle(color: _dimmed, fontSize: 10)),
                                ])),
                                Text('${_txnPrefix(t)}${_fmt(t.amount)}', style: TextStyle(color: _txnColor(t), fontSize: 13, fontWeight: FontWeight.w700)),
                                if (_auth.isDeveloper)
                                  const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.edit_rounded, color: _dimmed, size: 12)),
                              ]),
                            ),
                          )).toList()),
                        ),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                      if (!isExpanded) const Divider(color: _border, height: 1),
                    ]);
                  },
                ),
              ),
              // Bottom bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: Color(0xFF2A2A3E)))),
                child: Row(children: [
                  if (incomeTotal > 0) ...[
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Income', style: TextStyle(color: _dimmed, fontSize: 11)),
                      Text('+${_fmt(incomeTotal)}', style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(width: 20),
                  ],
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Expenses', style: TextStyle(color: _dimmed, fontSize: 11)),
                    Text(_fmt(expenseTotal), style: const TextStyle(color: _red, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Net', style: TextStyle(color: _dimmed, fontSize: 11)),
                    Text(_fmt(incomeTotal - expenseTotal),
                      style: TextStyle(color: incomeTotal >= expenseTotal ? _green : _red, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ]),
              ),
            ]),
    );
  }
}
