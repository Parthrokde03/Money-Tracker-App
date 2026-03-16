import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = ExpenseService();
  List<Expense> _allExpenses = [];
  bool _loading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Daily totals keyed by date string (yyyy-MM-dd)
  Map<String, double> _dailyTotals = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final expenses = await _service.loadExpenses();
    final Map<String, double> totals = {};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.dateTime);
      totals[key] = (totals[key] ?? 0) + e.amount;
    }
    setState(() {
      _allExpenses = expenses;
      _dailyTotals = totals;
      _loading = false;
    });
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(value);
  }

  List<Expense> _getExpensesForDay(DateTime day) {
    return _allExpenses.where((e) =>
        e.dateTime.year == day.year &&
        e.dateTime.month == day.month &&
        e.dateTime.day == day.day).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExpenses = _selectedDay != null
        ? _getExpensesForDay(_selectedDay!)
        : <Expense>[];
    final selectedTotal = _service.getTotal(selectedExpenses);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                if (_selectedDay != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDay!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatCurrency(selectedTotal),
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      color: Colors.white12, height: 1, indent: 20, endIndent: 20),
                  Expanded(
                    child: selectedExpenses.isEmpty
                        ? const Center(
                            child: Text(
                              'No expenses on this day',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: selectedExpenses.length,
                            itemBuilder: (_, i) {
                              final e = selectedExpenses[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A2E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.06)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('hh:mm a')
                                                .format(e.dateTime),
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(e.amount),
                                      style: const TextStyle(
                                        color: Color(0xFFFF6B6B),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ] else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Tap a date to see expenses',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TableCalendar<Expense>(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) {
          _focusedDay = focused;
        },
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: Colors.white70),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: Colors.white70),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white54, fontSize: 13),
          weekendStyle: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF6C63FF),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          cellMargin: const EdgeInsets.all(6),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, false, false),
          todayBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, true, false),
          selectedBuilder: (context, day, focusedDay) =>
              _buildDayCell(day, false, true),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final total = _dailyTotals[key];

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF6C63FF)
            : isToday
                ? const Color(0xFF6C63FF).withOpacity(0.3)
                : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (total != null)
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white70
                    : const Color(0xFFFF6B6B),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
