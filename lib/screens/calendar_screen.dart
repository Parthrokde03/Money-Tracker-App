import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
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
Color get _dimmed => AppColors.dimmed;

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = TransactionService();
  List<Transaction> _all = [];
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, double> _dailyExpenseTotals = {};

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final txns = await _service.loadTransactions();
    final Map<String, double> totals = {};
    for (final t in txns.where((t) => t.isExpense)) {
      final key = DateFormat('yyyy-MM-dd').format(t.dateTime);
      totals[key] = (totals[key] ?? 0) + t.amount;
    }
    setState(() { _all = txns; _dailyExpenseTotals = totals; _loading = false; });
  }

  String _fmt(double v) => NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(v);

  List<Transaction> _getForDay(DateTime day) =>
    _all.where((t) => t.dateTime.year == day.year && t.dateTime.month == day.month && t.dateTime.day == day.day).toList();

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

  @override
  Widget build(BuildContext context) {
    final selectedTxns = _selectedDay != null ? _getForDay(_selectedDay!) : <Transaction>[];
    final selectedExpenseTotal = _service.getExpenseTotal(selectedTxns);
    final selectedIncomeTotal = _service.getIncomeTotal(selectedTxns);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true, backgroundColor: _surface, elevation: 0, surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Column(children: [
              _buildCalendar(),
              if (_selectedDay != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(children: [
                    Text(DateFormat('dd MMM yyyy').format(_selectedDay!),
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (selectedIncomeTotal > 0)
                      Padding(padding: const EdgeInsets.only(right: 10),
                        child: Text('+${_fmt(selectedIncomeTotal)}', style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w600))),
                    if (selectedExpenseTotal > 0)
                      Text('-${_fmt(selectedExpenseTotal)}', style: const TextStyle(color: _red, fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                ),
                Divider(color: _border, height: 1, indent: 20, endIndent: 20),
                Expanded(
                  child: selectedTxns.isEmpty
                      ? Center(child: Text('No transactions on this day', style: TextStyle(color: _dimmed, fontSize: 13)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: selectedTxns.length,
                          itemBuilder: (_, i) {
                            final t = selectedTxns[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: _txnColor(t).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(_txnIcon(t), color: _txnColor(t), size: 15),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 2),
                                  Text('${_txnTag(t)} · ${DateFormat('hh:mm a').format(t.dateTime)}',
                                    style: TextStyle(color: _dimmed, fontSize: 11)),
                                ])),
                                Text('${_txnPrefix(t)}${_fmt(t.amount)}',
                                  style: TextStyle(color: _txnColor(t), fontSize: 14, fontWeight: FontWeight.w700)),
                              ]),
                            );
                          },
                        ),
                ),
              ] else
                Expanded(child: Center(child: Text('Tap a date to see transactions', style: TextStyle(color: _dimmed, fontSize: 13)))),
            ]),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: TableCalendar<Transaction>(
        firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) => setState(() { _selectedDay = selected; _focusedDay = focused; }),
        onPageChanged: (focused) => _focusedDay = focused,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: HeaderStyle(
          formatButtonVisible: false, titleCentered: true,
          titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.dimmed, size: 20),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.dimmed, size: 20),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.dimmed, fontSize: 12),
          weekendStyle: TextStyle(color: AppColors.dimmed, fontSize: 12),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: TextStyle(color: AppColors.textSecondary),
          todayDecoration: BoxDecoration(color: _accent.withOpacity(0.25), shape: BoxShape.circle),
          todayTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          selectedDecoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
          selectedTextStyle: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          cellMargin: const EdgeInsets.all(6),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, false, false),
          todayBuilder: (context, day, focusedDay) => _buildDayCell(day, true, false),
          selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, false, true),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final total = _dailyExpenseTotals[key];

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? _accent : isToday ? _accent.withOpacity(0.25) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('${day.day}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13,
          fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400)),
        if (total != null)
          Text('₹${total.toStringAsFixed(0)}', style: TextStyle(
            color: isSelected ? AppColors.textSecondary : _red, fontSize: 8, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
