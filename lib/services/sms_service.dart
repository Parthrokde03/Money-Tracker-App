import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'sms_parser.dart';
import 'transaction_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._();
  factory SmsService() => _instance;
  SmsService._();

  static const _enabledKey = 'sms_auto_entry_enabled';
  static const _lastCheckKey = 'sms_last_check_timestamp';
  static const _channel = MethodChannel('com.example.money_tracker/sms');

  final TransactionService _txnService = TransactionService();

  bool _enabled = false;
  bool get isEnabled => _enabled;

  final List<SmsParseResult> _pending = [];
  List<SmsParseResult> get pending => List.unmodifiable(_pending);

  /// Callback when new SMS transactions are detected
  void Function(List<SmsParseResult>)? onNewTransactions;

  String lastScanDebug = '';

  int _lastCheckTimestamp = 0;
  bool _checking = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _lastCheckTimestamp = prefs.getInt(_lastCheckKey) ?? 0;
    // If first time enabling, set timestamp to now so we don't scan old SMS
    if (_enabled && _lastCheckTimestamp == 0) {
      _lastCheckTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastCheckKey, _lastCheckTimestamp);
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (value && _lastCheckTimestamp == 0) {
      _lastCheckTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastCheckKey, _lastCheckTimestamp);
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestPermission');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Check for new SMS since last check (poll-on-resume approach).
  /// Returns new parsed results found since last check.
  Future<List<SmsParseResult>> checkNewSms() async {
    if (!_enabled) return [];
    if (_lastCheckTimestamp == 0) return [];
    // Prevent concurrent checks from racing and producing duplicates
    if (_checking) return [];
    _checking = true;

    try {
      List<dynamic> rawMessages;
      try {
        rawMessages = await _channel.invokeMethod(
          'getInboxSms',
          {'sinceTimestamp': _lastCheckTimestamp},
        );
      } catch (e) {
        return [];
      }

      // Update timestamp to now
      _lastCheckTimestamp = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, _lastCheckTimestamp);

      if (rawMessages.isEmpty) return [];

      final results = <SmsParseResult>[];
      for (final raw in rawMessages) {
        final map = Map<String, dynamic>.from(raw as Map);
        final address = map['address'] as String?;
        final body = map['body'] as String?;
        final dateMs = map['date'] as int?;

        if (body == null || body.isEmpty) continue;

        final date = dateMs != null
            ? DateTime.fromMillisecondsSinceEpoch(dateMs)
            : DateTime.now();

        final result = SmsParser.parse(body, sender: address, date: date);
        if (result != null && !_isDuplicate(result)) results.add(result);
      }

      if (results.isNotEmpty) {
        _pending.addAll(results);
        onNewTransactions?.call(results);
      }

      return results;
    } finally {
      _checking = false;
    }
  }

  /// Check if a parsed result already exists in pending list
  bool _isDuplicate(SmsParseResult result) {
    return _pending.any((p) =>
        p.amount == result.amount &&
        p.rawMessage == result.rawMessage &&
        p.dateTime == result.dateTime);
  }

  /// Scan inbox using native MethodChannel (full scan, last N days)
  Future<List<SmsParseResult>> scanInbox({int days = 30}) async {
    List<dynamic> rawMessages;
    try {
      rawMessages = await _channel.invokeMethod('getInboxSms', {'days': days});
    } catch (e) {
      lastScanDebug = 'Native error: $e';
      return [];
    }

    int totalRead = rawMessages.length;
    final results = <SmsParseResult>[];

    for (final raw in rawMessages) {
      final map = Map<String, dynamic>.from(raw as Map);
      final address = map['address'] as String?;
      final body = map['body'] as String?;
      final dateMs = map['date'] as int?;

      if (body == null || body.isEmpty) continue;

      final date = dateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : DateTime.now();

      final result = SmsParser.parse(body, sender: address, date: date);
      if (result != null && !_isDuplicate(result)) results.add(result);
    }

    // Update last check timestamp after full scan too
    _lastCheckTimestamp = DateTime.now().millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, _lastCheckTimestamp);

    lastScanDebug =
        'Read $totalRead SMS, Matched ${results.length} transactions';
    return results;
  }

  Future<Transaction> confirmTransaction(SmsParseResult result) async {
    final PaidVia? paidVia;
    if (result.isCredit) {
      // Credit to credit card = reducing CC outstanding (bill payment)
      // Credit to bank = income
      paidVia = result.isCreditCard ? PaidVia.creditCard : null;
    } else {
      // Debit from credit card or bank
      paidVia = result.isCreditCard ? PaidVia.creditCard : PaidVia.bank;
    }

    final TransactionType type;
    if (result.isCredit && result.isCreditCard) {
      // Money returned/refunded to credit card reduces CC outstanding
      type = TransactionType.billPayment;
    } else if (result.isCredit) {
      type = TransactionType.income;
    } else {
      type = TransactionType.expense;
    }

    final txn = Transaction(
      label: result.label,
      amount: result.amount,
      dateTime: result.dateTime,
      type: type,
      paidVia: paidVia,
      category: result.isCredit ? null : ExpenseCategory.other,
    );
    final saved = await _txnService.saveTransaction(txn);
    _pending.remove(result);
    return saved;
  }

  void dismissResult(SmsParseResult result) {
    _pending.remove(result);
  }

  void clearPending() => _pending.clear();
}
