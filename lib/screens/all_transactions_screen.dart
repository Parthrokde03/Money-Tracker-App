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

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});
  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _service = TransactionService();
  final _searchCtrl = TextEditingController();
  List<Transaction> _all = [];
  bool _loading = true;

  // Filters
  String _query = '';
  String _typeFilter = 'all'; // all, expense, income, bill
  String _paidViaFilter = 'all'; // all, bank, creditCard

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final txns = await _service.loadTransactions();
    if (!mounted) return;
    setState(() { _all = txns; _loading = false; });
  }

  List<Transaction> get _filtered {
    var list = List<Transaction>.from(_all);
    // Type filter
    if (_typeFilter == 'expense') list = list.where((t) => t.isExpense).toList();
    else if (_typeFilter == 'income') list = list.where((t) => t.isIncome).toList();
    else if (_typeFilter == 'bill') list = list.where((t) => t.isBillPayment).toList();
    // Paid via filter
    if (_paidViaFilter == 'bank') list = list.where((t) => t.paidVia == PaidVia.bank || t.isIncome).toList();
    else if (_paidViaFilter == 'creditCard') list = list.where((t) => t.paidVia == PaidVia.creditCard || t.isBillPayment).toList();
    // Search query
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final qNum = double.tryParse(_query);
      list = list.where((t) =>
        t.label.toLowerCase().contains(q) ||
        (t.category?.label.toLowerCase().contains(q) ?? false) ||
        t.amount.toStringAsFixed(2).contains(_query) ||
        (qNum != null && t.amount == qNum)
      ).toList();
    }
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  String _fmt(double v) => NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(v);
  Color _color(Transaction t) { if (t.isIncome) return _green; if (t.isBillPayment) return _orange; return _red; }
  String _prefix(Transaction t) => t.isIncome ? '+' : '-';
  IconData _icon(Transaction t) {
    if (t.isIncome) return Icons.arrow_downward_rounded;
    if (t.isBillPayment) return Icons.receipt_long_rounded;
    return t.category?.icon ?? Icons.shopping_bag_rounded;
  }
  String _subtitle(Transaction t) {
    if (t.isIncome) return 'Income';
    if (t.isBillPayment) return 'Bill Payment';
    final cat = t.category?.label ?? '';
    final via = t.paidVia == PaidVia.creditCard ? 'Credit Card' : 'Bank';
    return cat.isNotEmpty ? '$cat · $via' : via;
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
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (txn.id == null) return;
                  await _service.deleteTransaction(txn.id!);
                  await _load();
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Delete'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  if (txn.id == null) return;
                  await _service.updateTransaction(txn.id!, Transaction(id: txn.id, label: labelCtrl.text.trim(),
                    amount: double.parse(amountCtrl.text.trim()), dateTime: editDate, type: txn.type, paidVia: txn.paidVia, category: txn.category));
                  await _load();
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
    return InputDecoration(hintText: hint, hintStyle: TextStyle(color: _dimmed),
      prefixIcon: Icon(icon, color: _muted, size: 20), filled: true, fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true, backgroundColor: _surface, elevation: 0, surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: _accent))
        : Column(children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search transactions...', hintStyle: TextStyle(color: _dimmed, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: _dimmed, size: 20),
                  suffixIcon: _query.isNotEmpty ? IconButton(icon: Icon(Icons.close_rounded, color: _dimmed, size: 18),
                    onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
                  filled: true, fillColor: _surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                _chip('All', _typeFilter == 'all', () => setState(() => _typeFilter = 'all')),
                _chip('Expenses', _typeFilter == 'expense', () => setState(() => _typeFilter = 'expense')),
                _chip('Income', _typeFilter == 'income', () => setState(() => _typeFilter = 'income')),
                _chip('Bills', _typeFilter == 'bill', () => setState(() => _typeFilter = 'bill')),
                const SizedBox(width: 8),
                Container(width: 1, height: 20, color: _border),
                const SizedBox(width: 8),
                _chip('Bank', _paidViaFilter == 'bank', () => setState(() => _paidViaFilter = _paidViaFilter == 'bank' ? 'all' : 'bank')),
                _chip('Credit Card', _paidViaFilter == 'creditCard', () => setState(() => _paidViaFilter = _paidViaFilter == 'creditCard' ? 'all' : 'creditCard')),
              ])),
            ),
            const SizedBox(height: 8),
            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('${filtered.length} transaction${filtered.length != 1 ? 's' : ''}', style: TextStyle(color: _dimmed, fontSize: 11)),
                const Spacer(),
                if (filtered.isNotEmpty) Text('Total: ${_fmt(_service.getTotal(filtered))}', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 6),
            // Transaction list
            Expanded(
              child: filtered.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withOpacity(0.08)),
                    const SizedBox(height: 10),
                    Text('No transactions found', style: TextStyle(color: _dimmed, fontSize: 13)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];
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
                        onDismissed: (_) async { if (t.id != null) { await _service.deleteTransaction(t.id!); await _load(); } },
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
                                Text(t.label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${_subtitle(t)} · ${DateFormat('dd MMM · hh:mm a').format(t.dateTime)}',
                                  style: TextStyle(color: _dimmed, fontSize: 11)),
                              ])),
                              Text('${_prefix(t)}${_fmt(t.amount)}', style: TextStyle(color: _color(t), fontSize: 14, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ]),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _accent : _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? _accent : _border),
          ),
          child: Text(label, style: TextStyle(color: active ? Colors.white : _dimmed, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
