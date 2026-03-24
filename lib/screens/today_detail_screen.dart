import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/theme_service.dart';

Color get _bg => AppColors.bg;
Color get _surface => AppColors.surface;
const _accent = Color(0xFF6C63FF);
const _green = Color(0xFF2ECC71);
const _red = Color(0xFFFF6B6B);
const _orange = Color(0xFFE67E22);
Color get _border => AppColors.border;
Color get _muted => AppColors.muted;
Color get _dimmed => AppColors.dimmed;

class TodayDetailScreen extends StatefulWidget {
  final List<Transaction> transactions;
  const TodayDetailScreen({super.key, required this.transactions});
  @override
  State<TodayDetailScreen> createState() => _TodayDetailScreenState();
}

class _TodayDetailScreenState extends State<TodayDetailScreen> {
  final _service = TransactionService();
  late List<Transaction> _txns;
  bool _changed = false;

  @override
  void initState() { super.initState(); _txns = List<Transaction>.from(widget.transactions); }

  Future<void> _reload() async {
    final all = await _service.loadTransactions();
    setState(() { _txns = _service.getTodayTransactions(all); });
  }

  String _fmt(double v) => NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(v);

  Color _color(Transaction t) { if (t.isIncome) return _green; if (t.isBillPayment) return _orange; return _red; }
  String _prefix(Transaction t) => t.isIncome ? '+' : '-';

  String _subtitle(Transaction t) {
    if (t.isIncome) return 'Income';
    if (t.isBillPayment) return 'Bill Payment';
    final cat = t.category?.label ?? '';
    final via = t.paidVia == PaidVia.creditCard ? 'Credit Card' : 'Bank';
    return cat.isNotEmpty ? '$cat · $via' : via;
  }

  IconData _icon(Transaction t) {
    if (t.isIncome) return Icons.arrow_downward_rounded;
    if (t.isBillPayment) return Icons.receipt_long_rounded;
    return t.category?.icon ?? Icons.shopping_bag_rounded;
  }

  void _showEditDialog(Transaction txn) {
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
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            TextFormField(controller: labelCtrl, style: TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Label', Icons.label_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter label' : null),
            const SizedBox(height: 14),
            TextFormField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.textPrimary), decoration: _inputDecoration('Amount', Icons.currency_rupee_rounded),
              validator: (v) { if (v == null || v.trim().isEmpty) return 'Enter amount'; if (double.tryParse(v.trim()) == null) return 'Invalid number'; if (double.parse(v.trim()) <= 0) return 'Must be > 0'; return null; }),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: editDate, firstDate: DateTime(2020), lastDate: DateTime.now(),
                  builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: _accent, surface: _surface)), child: child!));
                if (picked != null) setSheetState(() => editDate = DateTime(picked.year, picked.month, picked.day, txn.dateTime.hour, txn.dateTime.minute, txn.dateTime.second));
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, color: _dimmed, size: 18),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd MMM yyyy').format(editDate), style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () async { Navigator.pop(ctx); await _deleteTransaction(txn); },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Delete'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  await _updateTransaction(txn, labelCtrl.text.trim(), double.parse(amountCtrl.text.trim()), editDate);
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

  Future<void> _updateTransaction(Transaction old, String newLabel, double newAmount, DateTime newDate) async {
    if (old.id == null) return;
    await _service.updateTransaction(old.id!, Transaction(id: old.id, label: newLabel, amount: newAmount, dateTime: newDate, type: old.type, paidVia: old.paidVia, category: old.category));
    _changed = true; await _reload();
  }

  Future<void> _deleteTransaction(Transaction txn) async {
    if (txn.id == null) return;
    await _service.deleteTransaction(txn.id!);
    _changed = true; await _reload();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(hintText: hint, hintStyle: TextStyle(color: _dimmed),
      prefixIcon: Icon(icon, color: _muted, size: 20), filled: true, fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)));
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Transaction>.from(_txns)..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final expenseTotal = _service.getExpenseTotal(_txns);
    final incomeTotal = _service.getIncomeTotal(_txns);
    final today = DateFormat('EEEE, dd MMMM').format(DateTime.now());

    // Group by type for clarity
    final incomes = sorted.where((t) => t.isIncome).toList();
    final expenses = sorted.where((t) => t.isExpense).toList();
    final bills = sorted.where((t) => t.isBillPayment).toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) { if (didPop && _changed) {} },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(today, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          centerTitle: true, backgroundColor: _surface, elevation: 0, surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        body: sorted.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_rounded, size: 56, color: AppColors.dimmed.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('No transactions today', style: TextStyle(color: _dimmed, fontSize: 15)),
              ]))
            : Column(children: [
                Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
                  // Income section
                  if (incomes.isNotEmpty) ...[
                    _sectionHeader('Income', '+${_fmt(incomeTotal)}', _green),
                    const SizedBox(height: 8),
                    ...incomes.map((t) => _txnTile(t)),
                    const SizedBox(height: 16),
                  ],
                  // Expenses section
                  if (expenses.isNotEmpty) ...[
                    _sectionHeader('Expenses', '-${_fmt(expenseTotal)}', _red),
                    const SizedBox(height: 8),
                    ...expenses.map((t) => _txnTile(t)),
                    if (bills.isNotEmpty) const SizedBox(height: 16),
                  ],
                  // Bill payments
                  if (bills.isNotEmpty) ...[
                    _sectionHeader('Bill Payments', '-${_fmt(_service.getTotal(bills))}', _orange),
                    const SizedBox(height: 8),
                    ...bills.map((t) => _txnTile(t)),
                  ],
                ])),
                // Bottom summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(color: _surface, border: Border(top: BorderSide(color: AppColors.divider))),
                  child: Row(children: [
                    if (incomeTotal > 0) ...[
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Income', style: TextStyle(color: _dimmed, fontSize: 11)),
                        Text('+${_fmt(incomeTotal)}', style: const TextStyle(color: _green, fontSize: 14, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(width: 24),
                    ],
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Expenses', style: TextStyle(color: _dimmed, fontSize: 11)),
                      Text('-${_fmt(expenseTotal)}', style: const TextStyle(color: _red, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Net', style: TextStyle(color: _dimmed, fontSize: 11)),
                      Text(_fmt(incomeTotal - expenseTotal),
                        style: TextStyle(color: incomeTotal >= expenseTotal ? _green : _red, fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                ),
              ]),
      ),
    );
  }

  Widget _sectionHeader(String label, String amount, Color color) {
    return Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      const Spacer(),
      Text(amount, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _txnTile(Transaction t) {
    return Dismissible(
      key: ValueKey(t.id ?? t.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: _surface, title: Text('Delete?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          content: Text('Remove "${t.label}" (${_fmt(t.amount)})?', style: TextStyle(color: _dimmed, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: _dimmed))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
          ],
        )) ?? false;
      },
      onDismissed: (_) => _deleteTransaction(t),
      child: GestureDetector(
        onTap: () => _showEditDialog(t),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _color(t).withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
              child: Icon(_icon(t), color: _color(t), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${_subtitle(t)} · ${DateFormat('hh:mm a').format(t.dateTime)}',
                style: TextStyle(color: _dimmed, fontSize: 11)),
            ])),
            Text('${_prefix(t)}${_fmt(t.amount)}', style: TextStyle(color: _color(t), fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
