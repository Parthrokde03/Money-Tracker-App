import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import 'calendar_screen.dart';
import 'month_detail_screen.dart';
import 'today_detail_screen.dart';
import 'account_screen.dart';

// ── Design Tokens ──
const _bg = Color(0xFF0F0F1A);
const _surface = Color(0xFF1A1A2E);
const _accent = Color(0xFF6C63FF);
const _green = Color(0xFF2ECC71);
const _red = Color(0xFFFF6B6B);
const _orange = Color(0xFFE67E22);
const _border = Color(0x0FFFFFFF);
const _muted = Color(0x99FFFFFF);
const _dimmed = Color(0x59FFFFFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _billAmountController = TextEditingController();
  final _billFormKey = GlobalKey<FormState>();
  final _service = TransactionService();
  final _auth = AuthService();

  List<Transaction> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChange);
    _loadData();
  }

  void _onAuthChange() { if (mounted) setState(() {}); }

  Future<void> _loadData() async {
    final txns = await _service.loadTransactions();
    setState(() { _all = txns; _loading = false; });
  }

  String _fmt(double v) =>
      NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(v);

  String _fmtShort(double v) {
    if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChange);
    _billAmountController.dispose();
    super.dispose();
  }

  // ── Insight Generator ──
  String? _buildInsight(List<Transaction> monthTxns) {
    final expenses = _service.getExpenses(monthTxns);
    final income = _service.getIncomeTotal(monthTxns);
    final expenseTotal = _service.getExpenseTotal(monthTxns);

    if (expenses.isEmpty && income == 0) return null;

    // Top category insight
    if (expenses.isNotEmpty) {
      final Map<ExpenseCategory, double> catTotals = {};
      for (final t in expenses) {
        final cat = t.category ?? ExpenseCategory.other;
        catTotals[cat] = (catTotals[cat] ?? 0) + t.amount;
      }
      final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final pct = (top.value / expenseTotal * 100).toStringAsFixed(0);

      if (income > expenseTotal) {
        final saved = income - expenseTotal;
        return '💡 You saved ${_fmtShort(saved)} this month · Top: ${top.key.label} ($pct%)';
      }
      return '💡 Top spending: ${top.key.label} · ${_fmtShort(top.value)} ($pct%)';
    }

    if (income > 0) return '💡 ${_fmtShort(income)} earned this month, no expenses yet';
    return null;
  }

  // ── Add Expense Sheet ──
  void _showAddExpenseSheet() {
    final amtCtrl = TextEditingController();
    final lblCtrl = TextEditingController();
    final expFormKey = GlobalKey<FormState>();
    PaidVia sheetPaidVia = PaidVia.bank;
    ExpenseCategory sheetCategory = ExpenseCategory.food;
    bool devMode = false;
    DateTime? customDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: expFormKey,
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                const Text('Add Expense', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amtCtrl,
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: lblCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Label', Icons.label_outline_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter label' : null,
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Category', style: TextStyle(color: _muted, fontSize: 13))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ExpenseCategory.values.map((cat) {
                    final selected = sheetCategory == cat;
                    return GestureDetector(
                      onTap: () => setSheetState(() => sheetCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _accent : _bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? _accent : _border),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(cat.icon, size: 14, color: selected ? Colors.white : Colors.white54),
                          const SizedBox(width: 6),
                          Text(cat.label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Paid via', style: TextStyle(color: _muted, fontSize: 13)),
                  const SizedBox(width: 12),
                  _pillButton('Bank', sheetPaidVia == PaidVia.bank, () => setSheetState(() => sheetPaidVia = PaidVia.bank)),
                  const SizedBox(width: 8),
                  _pillButton('Credit Card', sheetPaidVia == PaidVia.creditCard, () => setSheetState(() => sheetPaidVia = PaidVia.creditCard)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  SizedBox(width: 20, height: 20, child: Checkbox(
                    value: devMode,
                    onChanged: (v) => setSheetState(() { devMode = v ?? false; if (!devMode) customDate = null; }),
                    activeColor: _accent, side: const BorderSide(color: _dimmed),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
                  const SizedBox(width: 8),
                  const Text('Developer', style: TextStyle(color: _dimmed, fontSize: 11)),
                ]),
                if (devMode) ...[
                  const SizedBox(height: 10),
                  _datePicker(ctx, customDate, (d) => setSheetState(() => customDate = d)),
                ],
                const SizedBox(height: 20),
                _actionButton('Add Expense', _accent, () async {
                  if (!expFormKey.currentState!.validate()) return;
                  final now = DateTime.now();
                  final txnDate = (devMode && customDate != null)
                      ? DateTime(customDate!.year, customDate!.month, customDate!.day, now.hour, now.minute, now.second)
                      : now;
                  await _service.saveTransaction(Transaction(
                    label: lblCtrl.text.trim(), amount: double.parse(amtCtrl.text.trim()),
                    dateTime: txnDate, type: TransactionType.expense, paidVia: sheetPaidVia, category: sheetCategory,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadData();
                  _snack('Expense added');
                }),
              ],
            )),
          ),
        ),
      ),
    );
  }

  // ── Add Income Sheet ──
  void _showAddIncomeSheet() {
    final incAmtCtrl = TextEditingController();
    final incLblCtrl = TextEditingController();
    final incFormKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: incFormKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            const Text('Add Income', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextFormField(controller: incAmtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Amount', Icons.currency_rupee_rounded),
              validator: (v) { if (v == null || v.trim().isEmpty) return 'Enter amount'; if (double.tryParse(v.trim()) == null) return 'Invalid number'; if (double.parse(v.trim()) <= 0) return 'Must be > 0'; return null; }),
            const SizedBox(height: 14),
            TextFormField(controller: incLblCtrl, style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Label (e.g. Salary)', Icons.label_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter label' : null),
            const SizedBox(height: 20),
            _actionButton('Add Income', _green, () async {
              if (!incFormKey.currentState!.validate()) return;
              await _service.saveTransaction(Transaction(
                label: incLblCtrl.text.trim(), amount: double.parse(incAmtCtrl.text.trim()),
                dateTime: DateTime.now(), type: TransactionType.income,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadData();
              _snack('Income added');
            }),
          ]),
        ),
      ),
    );
  }

  // ── Pay Bill Sheet ──
  void _showPayBillSheet() {
    final outstanding = _service.getCreditCardOutstanding(_all);
    _billAmountController.text = outstanding > 0 ? outstanding.toStringAsFixed(2) : '';
    bool payFull = true;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(key: _billFormKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 16),
            const Text('Pay Credit Card Bill', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Outstanding: ${_fmt(outstanding)}', style: const TextStyle(color: _red, fontSize: 14)),
            const SizedBox(height: 18),
            Row(children: [
              _pillButton('Full Payment', payFull, () => setSheetState(() { payFull = true; _billAmountController.text = outstanding.toStringAsFixed(2); })),
              const SizedBox(width: 10),
              _pillButton('Partial', !payFull, () => setSheetState(() { payFull = false; _billAmountController.clear(); })),
            ]),
            const SizedBox(height: 14),
            TextFormField(controller: _billAmountController, enabled: !payFull,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white), decoration: _inputDecoration('Amount', Icons.currency_rupee_rounded),
              validator: (v) { if (v == null || v.trim().isEmpty) return 'Enter amount'; final val = double.tryParse(v.trim()); if (val == null) return 'Invalid number'; if (val <= 0) return 'Must be > 0'; if (val > outstanding) return 'Exceeds outstanding'; return null; }),
            const SizedBox(height: 20),
            _actionButton('Pay Now', _orange, outstanding <= 0 ? null : () async {
              if (!_billFormKey.currentState!.validate()) return;
              await _service.saveTransaction(Transaction(
                label: payFull ? 'CC Bill – Full Payment' : 'CC Bill – Partial Payment',
                amount: double.parse(_billAmountController.text.trim()),
                dateTime: DateTime.now(), type: TransactionType.billPayment,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadData();
              _snack('Bill payment recorded');
            }),
          ])),
        ),
      ),
    );
  }

  // ── Shared Sheet Widgets ──
  Widget _sheetHandle() => Container(width: 40, height: 4, decoration: BoxDecoration(color: _dimmed, borderRadius: BorderRadius.circular(2)));

  Widget _pillButton(String label, bool active, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? _accent : _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? _accent : _border)),
        child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w600))),
      ),
    ));
  }

  Widget _actionButton(String label, Color color, VoidCallback? onTap) {
    return SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ));
  }

  Widget _datePicker(BuildContext ctx, DateTime? current, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: ctx, initialDate: current ?? DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: _accent, surface: _surface)), child: child!));
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: _dimmed, size: 18),
          const SizedBox(width: 12),
          Text(current != null ? DateFormat('dd MMM yyyy').format(current) : 'Select Date',
            style: TextStyle(color: current != null ? Colors.white : _dimmed, fontSize: 14)),
        ]),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTxns = _service.getMonthTransactions(_all);
    final todayTxns = _service.getTodayTransactions(_all);
    final monthExpenseTotal = _service.getExpenseTotal(monthTxns);
    final monthIncomeTotal = _service.getIncomeTotal(monthTxns);
    final todayExpenseTotal = _service.getExpenseTotal(todayTxns);
    final todayIncomeTotal = _service.getIncomeTotal(todayTxns);
    final bankBalance = _service.getBankBalance(_all);
    final ccOutstanding = _service.getCreditCardOutstanding(_all);
    final insight = _buildInsight(monthTxns);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(context).openDrawer())),
        title: const Text('Money Tracker', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        centerTitle: true, backgroundColor: _surface, elevation: 0, surfaceTintColor: Colors.transparent,
        actions: [
          if (_auth.isDeveloper)
            IconButton(icon: const Icon(Icons.account_circle_rounded, color: _accent), tooltip: 'Logout',
              onPressed: () { _auth.logout(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Logged out'), backgroundColor: Colors.orange.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); }),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : RefreshIndicator(
              color: _accent,
              backgroundColor: _surface,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ── 1. Hero Balance Card ──
                  _buildHeroBalance(bankBalance, ccOutstanding),
                  const SizedBox(height: 16),

                  // ── 2. Insight Strip ──
                  if (insight != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: _accent.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: _accent.withOpacity(0.12))),
                      child: Text(insight, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  if (insight != null) const SizedBox(height: 16),

                  // ── 3. Quick Stats Row ──
                  _buildQuickStats(now: now, monthExpense: monthExpenseTotal, monthIncome: monthIncomeTotal, todayExpense: todayExpenseTotal, todayIncome: todayIncomeTotal, monthTxns: monthTxns, todayTxns: todayTxns),
                  const SizedBox(height: 20),

                  // ── 4. Recent Transactions ──
                  _buildRecentTransactions(todayTxns),
                  const SizedBox(height: 20),

                  // ── 5. Spending Breakdown (Pie) ──
                  _buildCategoryPieChart(monthTxns),
                  const SizedBox(height: 16),

                  // ── 6. Monthly Trend (Bar) ──
                  _MonthlyBarChart(allTransactions: _all, fmt: _fmt, fmtShort: _fmtShort),
                ]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFabMenu(context),
        backgroundColor: _accent, shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Hero Balance Card (softer gradient, bank + CC breakdown) ──
  Widget _buildHeroBalance(double bankBalance, double ccOutstanding) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B54E0), Color(0xFF3D2FB5)], // softer purple
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text('Total Balance', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(_fmt(bankBalance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 12),
        // Bank + CC breakdown row
        Row(children: [
          const Icon(Icons.account_balance_rounded, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          Text('Bank', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          const SizedBox(width: 4),
          Text(_fmtShort(bankBalance), style: TextStyle(color: bankBalance >= 0 ? Colors.white70 : const Color(0xFFFF8A80), fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: ccOutstanding > 0 ? _showPayBillSheet : null,
            child: Row(children: [
              const Icon(Icons.credit_card_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text('CC Due', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              const SizedBox(width: 4),
              Text(_fmtShort(ccOutstanding), style: TextStyle(
                color: ccOutstanding > 0 ? const Color(0xFFFFB74D) : Colors.white54,
                fontSize: 12, fontWeight: FontWeight.w600)),
              if (ccOutstanding > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text('PAY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              ],
            ]),
          ),
        ]),
      ]),
    );
  }

  // ── Quick Stats Row ──
  Widget _buildQuickStats({
    required DateTime now, required double monthExpense, required double monthIncome,
    required double todayExpense, required double todayIncome,
    required List<Transaction> monthTxns, required List<Transaction> todayTxns,
  }) {
    return Row(children: [
      Expanded(child: _QuickStatCard(
        label: 'This Month', sublabel: DateFormat('MMM yyyy').format(now),
        expense: _fmtShort(monthExpense),
        income: monthIncome > 0 ? '+${_fmtShort(monthIncome)}' : null,
        icon: Icons.calendar_month_rounded, accentColor: _accent,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => MonthDetailScreen(transactions: monthTxns, monthLabel: DateFormat('MMMM yyyy').format(now))));
          await _loadData();
        },
      )),
      const SizedBox(width: 12),
      Expanded(child: _QuickStatCard(
        label: 'Today', sublabel: DateFormat('dd MMM').format(now),
        expense: _fmtShort(todayExpense),
        income: todayIncome > 0 ? '+${_fmtShort(todayIncome)}' : null,
        icon: Icons.today_rounded, accentColor: _red,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TodayDetailScreen(transactions: todayTxns)));
          await _loadData();
        },
      )),
    ]);
  }

  // ── Recent Transactions (last 5 today) ──
  Widget _buildRecentTransactions(List<Transaction> todayTxns) {
    if (todayTxns.isEmpty) return const SizedBox.shrink();

    final sorted = List<Transaction>.from(todayTxns)..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final recent = sorted.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Recent', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('Today · ${recent.length} item${recent.length > 1 ? 's' : ''}', style: const TextStyle(color: _dimmed, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        ...recent.map((t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: _txnColor(t).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(_txnIcon(t), color: _txnColor(t), size: 14),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              Text(_txnSubtitle(t), style: const TextStyle(color: _dimmed, fontSize: 10)),
            ])),
            Text('${t.isIncome ? '+' : '-'}${_fmtShort(t.amount)}',
              style: TextStyle(color: _txnColor(t), fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        )),
      ]),
    );
  }

  Color _txnColor(Transaction t) {
    if (t.isIncome) return _green;
    if (t.isBillPayment) return _orange;
    return _red;
  }

  IconData _txnIcon(Transaction t) {
    if (t.isIncome) return Icons.arrow_downward_rounded;
    if (t.isBillPayment) return Icons.receipt_long_rounded;
    return t.category?.icon ?? Icons.shopping_bag_rounded;
  }

  String _txnSubtitle(Transaction t) {
    if (t.isIncome) return 'Income · ${DateFormat('hh:mm a').format(t.dateTime)}';
    if (t.isBillPayment) return 'Bill Payment · ${DateFormat('hh:mm a').format(t.dateTime)}';
    final cat = t.category?.label ?? '';
    final via = t.paidVia == PaidVia.creditCard ? 'Credit Card' : 'Bank';
    return '$cat · $via · ${DateFormat('hh:mm a').format(t.dateTime)}';
  }

  // ── Pie Chart Section ──
  Widget _buildCategoryPieChart(List<Transaction> monthTxns) {
    final expenses = _service.getExpenses(monthTxns);
    final Map<ExpenseCategory, double> catTotals = {};
    for (final t in expenses) {
      final cat = t.category ?? ExpenseCategory.other;
      catTotals[cat] = (catTotals[cat] ?? 0) + t.amount;
    }
    final total = catTotals.values.fold(0.0, (s, v) => s + v);
    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _PieChartCard(sorted: sorted, total: total, fmt: _fmt, fmtShort: _fmtShort, isEmpty: expenses.isEmpty);
  }

  // ── FAB Menu ──
  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _sheetHandle(),
          const SizedBox(height: 20),
          _fabOption(icon: Icons.arrow_upward_rounded, label: 'Add Expense', subtitle: 'Track a new purchase', color: _red,
            onTap: () { Navigator.pop(ctx); _showAddExpenseSheet(); }),
          const SizedBox(height: 12),
          _fabOption(icon: Icons.arrow_downward_rounded, label: 'Add Income', subtitle: 'Record salary or earnings', color: _green,
            onTap: () { Navigator.pop(ctx); _showAddIncomeSheet(); }),
        ]),
      ),
    );
  }

  Widget _fabOption({required IconData icon, required String label, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.12))),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: _dimmed, fontSize: 11)),
          ])),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.3), size: 20),
        ]),
      ),
    );
  }

  // ── Drawer ──
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _surface,
      child: SafeArea(child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5B54E0), Color(0xFF3D2FB5)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
            SizedBox(height: 12),
            Text('Money Tracker', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 8),
        if (!_auth.isDeveloper)
          ListTile(leading: const Icon(Icons.person_rounded, color: Colors.white70),
            title: const Text('Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())); }),
        ListTile(leading: const Icon(Icons.home_rounded, color: Colors.white70),
          title: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          onTap: () => Navigator.pop(context)),
        ListTile(leading: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
          title: const Text('Calendar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())); }),
      ])),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _dimmed),
      prefixIcon: Icon(icon, color: _muted, size: 20), filled: true, fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}


// ── Quick Stat Card ──
class _QuickStatCard extends StatelessWidget {
  final String label, sublabel, expense;
  final String? income;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickStatCard({required this.label, required this.sublabel, required this.expense,
    required this.icon, required this.accentColor, required this.onTap, this.income});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: accentColor, size: 15),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, color: _dimmed, size: 14),
          ]),
          const SizedBox(height: 2),
          Text(sublabel, style: const TextStyle(color: _dimmed, fontSize: 10)),
          const SizedBox(height: 8),
          // Expense line
          Row(children: [
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(expense, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)))),
          ]),
          if (income != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(income!, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ],
        ]),
      ),
    );
  }
}


// ── Pie Chart Card ──
class _PieChartCard extends StatefulWidget {
  final List<MapEntry<ExpenseCategory, double>> sorted;
  final double total;
  final String Function(double) fmt;
  final String Function(double) fmtShort;
  final bool isEmpty;

  const _PieChartCard({required this.sorted, required this.total, required this.fmt, required this.fmtShort, required this.isEmpty});

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Spending Breakdown', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(DateFormat('MMM yyyy').format(DateTime.now()), style: const TextStyle(color: _dimmed, fontSize: 11)),
        ]),
        if (widget.isEmpty) ...[
          const SizedBox(height: 32),
          Center(child: Column(children: [
            Icon(Icons.pie_chart_outline_rounded, size: 40, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 10),
            const Text('No expenses this month', style: TextStyle(color: _dimmed, fontSize: 12)),
            const SizedBox(height: 2),
            const Text('Add an expense to see your breakdown', style: TextStyle(color: Color(0x33FFFFFF), fontSize: 10)),
          ])),
          const SizedBox(height: 32),
        ] else ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                pieTouchData: PieTouchData(touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) { _touchedIndex = -1; return; }
                    _touchedIndex = response.touchedSection!.touchedSectionIndex;
                  });
                }),
                sectionsSpace: 2, centerSpaceRadius: 45,
                sections: _buildSections(),
              )),
              _touchedIndex >= 0 && _touchedIndex < widget.sorted.length
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(widget.sorted[_touchedIndex].key.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(widget.fmt(widget.sorted[_touchedIndex].value), style: TextStyle(color: widget.sorted[_touchedIndex].key.color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ])
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Total', style: TextStyle(color: _dimmed, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(widget.fmtShort(widget.total), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
            ]),
          ),
          const SizedBox(height: 14),
          // Legend: Category • ₹Amount (XX%)
          ...widget.sorted.map((e) {
            final pct = (e.value / widget.total * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Expanded(child: Text('${e.key.label} · ${widget.fmtShort(e.value)} ($pct%)',
                  style: const TextStyle(color: _muted, fontSize: 12))),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return List.generate(widget.sorted.length, (i) {
      final e = widget.sorted[i];
      final isTouched = i == _touchedIndex;
      final pct = (e.value / widget.total * 100);
      return PieChartSectionData(
        color: e.key.color, value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: TextStyle(color: Colors.white, fontSize: isTouched ? 13 : 10, fontWeight: FontWeight.w700),
        radius: isTouched ? 50 : 40,
      );
    });
  }
}


// ── Monthly Bar Chart ──
class _MonthlyBarChart extends StatelessWidget {
  final List<Transaction> allTransactions;
  final String Function(double) fmt;
  final String Function(double) fmtShort;

  const _MonthlyBarChart({required this.allTransactions, required this.fmt, required this.fmtShort});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Build last 6 months, but only keep months with data + always include current
    final List<_MonthData> allMonths = [];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      double income = 0, expense = 0;
      for (final t in allTransactions) {
        if (t.dateTime.year == month.year && t.dateTime.month == month.month) {
          if (t.isIncome) income += t.amount;
          if (t.isExpense) expense += t.amount;
        }
      }
      allMonths.add(_MonthData(label: DateFormat('MMM').format(month), income: income, expense: expense, isCurrent: i == 0));
    }

    // Filter: keep months with data + always current month
    final months = allMonths.where((m) => m.income > 0 || m.expense > 0 || m.isCurrent).toList();

    final maxVal = months.fold<double>(0, (m, d) {
      final bigger = d.income > d.expense ? d.income : d.expense;
      return bigger > m ? bigger : m;
    });

    // Current month savings insight
    final current = months.isNotEmpty ? months.last : null;
    String? savingsInsight;
    if (current != null && (current.income > 0 || current.expense > 0)) {
      final diff = current.income - current.expense;
      if (diff > 0) {
        savingsInsight = '✅ You saved ${fmtShort(diff)} this month';
      } else if (diff < 0 && current.income > 0) {
        savingsInsight = '⚠️ You overspent by ${fmtShort(diff.abs())} this month';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Monthly Trend', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          _legendDot(_green, 'Income'),
          const SizedBox(width: 10),
          _legendDot(_red, 'Expense'),
        ]),
        const SizedBox(height: 2),
        Text('Last ${months.length} month${months.length > 1 ? 's' : ''} with activity', style: const TextStyle(color: _dimmed, fontSize: 10)),
        if (maxVal == 0) ...[
          const SizedBox(height: 32),
          Center(child: Column(children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 10),
            const Text('No data for previous months', style: TextStyle(color: _dimmed, fontSize: 12)),
            const SizedBox(height: 2),
            const Text('Start adding transactions to see trends', style: TextStyle(color: Color(0x33FFFFFF), fontSize: 10)),
          ])),
          const SizedBox(height: 32),
        ] else ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.25,
              barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = months[group.x.toInt()];
                  final isIncome = rodIndex == 0;
                  return BarTooltipItem('${isIncome ? "Income" : "Expense"}\n${fmt(isIncome ? d.income : d.expense)}',
                    TextStyle(color: isIncome ? _green : _red, fontSize: 11, fontWeight: FontWeight.w600));
                },
              )),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    String text;
                    if (value >= 100000) { text = '${(value / 100000).toStringAsFixed(1)}L'; }
                    else if (value >= 1000) { text = '${(value / 1000).toStringAsFixed(0)}K'; }
                    else { text = value.toStringAsFixed(0); }
                    return Text(text, style: const TextStyle(color: _dimmed, fontSize: 9));
                  },
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 6),
                      child: Text(months[idx].label, style: TextStyle(
                        color: months[idx].isCurrent ? Colors.white : _dimmed,
                        fontSize: 10, fontWeight: months[idx].isCurrent ? FontWeight.w600 : FontWeight.w400)));
                  },
                )),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxVal > 0 ? maxVal / 3 : 1,
                getDrawingHorizontalLine: (value) => const FlLine(color: Color(0x0AFFFFFF), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(months.length, (i) {
                final d = months[i];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: d.income, color: _green, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                  BarChartRodData(toY: d.expense, color: _red, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                ]);
              }),
            )),
          ),
          // Savings insight
          if (savingsInsight != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
              child: Text(savingsInsight, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: _dimmed, fontSize: 10)),
    ]);
  }
}

class _MonthData {
  final String label;
  final double income, expense;
  final bool isCurrent;
  _MonthData({required this.label, required this.income, required this.expense, this.isCurrent = false});
}
