import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import 'gmail_parser.dart';
import 'sms_parser.dart';
import 'transaction_service.dart';

/// Authenticated HTTP client that injects Google Sign-In auth headers.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

class GmailService {
  static final GmailService _instance = GmailService._();
  factory GmailService() => _instance;
  GmailService._();

  static const _enabledKey = 'gmail_scan_enabled';
  static const _lastCheckKey = 'gmail_last_check_timestamp';

  final TransactionService _txnService = TransactionService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/gmail.readonly'],
  );

  bool _enabled = false;
  bool get isEnabled => _enabled;

  bool _signedIn = false;
  bool get isSignedIn => _signedIn;

  String? _userEmail;
  String? get userEmail => _userEmail;

  final List<SmsParseResult> _pending = [];
  List<SmsParseResult> get pending => List.unmodifiable(_pending);

  void Function(List<SmsParseResult>)? onNewTransactions;

  String lastScanDebug = '';
  int _lastCheckTimestamp = 0;
  bool _checking = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _lastCheckTimestamp = prefs.getInt(_lastCheckKey) ?? 0;

    // Try silent sign-in to restore session
    if (_enabled) {
      try {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          _signedIn = true;
          _userEmail = account.email;
        }
      } catch (_) {}
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      _signedIn = true;
      _userEmail = account.email;
      return true;
    } catch (e) {
      debugPrint('Gmail sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _signedIn = false;
    _userEmail = null;
    _enabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
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

  Future<gmail.GmailApi?> _getGmailApi() async {
    final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) return null;
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) return null;
    final client = _GoogleAuthClient({'Authorization': 'Bearer $token'});
    return gmail.GmailApi(client);
  }

  /// Bank sender keywords to filter Gmail search query
  static const _bankQuerySenders = [
    'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'pnb', 'canara',
    'idfc', 'yes bank', 'indusind', 'bob', 'union bank', 'federal',
    'bandhan', 'rbl', 'au bank', 'iob', 'indian bank', 'uco',
    'central bank', 'sbm', 'paytm', 'phonepe', 'gpay', 'jupiter',
    'fi.money', 'niyox', 'slice', 'cred',
  ];

  /// Build Gmail search query for bank emails
  static String _buildSearchQuery({int? afterTimestamp}) {
    // Search by transaction keywords — specific enough to find bank emails
    // without restricting by sender (bank emails come from varied addresses)
    final keywords = '(credited OR debited OR "transaction successful" OR "payment successful" OR "you have paid" OR "amount debited" OR "amount credited" OR "UPI transaction")';
    final amountPattern = '(INR OR Rs OR rupees)';
    var query = '$keywords $amountPattern';
    if (afterTimestamp != null) {
      final afterSec = afterTimestamp ~/ 1000;
      query += ' after:$afterSec';
    }
    return query;
  }

  /// Check for new bank emails since last check.
  Future<List<SmsParseResult>> checkNewEmails() async {
    if (!_enabled || !_signedIn) return [];
    if (_checking) return [];
    _checking = true;

    try {
      final api = await _getGmailApi();
      if (api == null) return [];

      final query = _buildSearchQuery(
        afterTimestamp: _lastCheckTimestamp > 0 ? _lastCheckTimestamp : null,
      );

      final results = await _fetchAndParse(api, query, maxResults: 20);

      // Update timestamp
      _lastCheckTimestamp = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, _lastCheckTimestamp);

      if (results.isNotEmpty) {
        _pending.addAll(results);
        onNewTransactions?.call(results);
      }

      return results;
    } catch (e) {
      debugPrint('Gmail check error: $e');
      return [];
    } finally {
      _checking = false;
    }
  }

  /// Full scan of bank emails from last N days.
  Future<List<SmsParseResult>> scanInbox({int days = 30}) async {
    final api = await _getGmailApi();
    if (api == null) {
      lastScanDebug = 'Not signed in to Google';
      return [];
    }

    final afterTs = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final query = _buildSearchQuery(afterTimestamp: afterTs);

    try {
      final results = await _fetchAndParse(api, query, maxResults: 50);

      _lastCheckTimestamp = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastCheckKey, _lastCheckTimestamp);

      lastScanDebug = 'Found ${results.length} bank transactions in emails';
      return results;
    } catch (e) {
      lastScanDebug = 'Gmail scan error: $e';
      return [];
    }
  }

  Future<List<SmsParseResult>> _fetchAndParse(
    gmail.GmailApi api,
    String query, {
    int maxResults = 20,
  }) async {
    final msgList = await api.users.messages.list(
      'me',
      q: query,
      maxResults: maxResults,
    );

    final messages = msgList.messages;
    if (messages == null || messages.isEmpty) return [];

    final results = <SmsParseResult>[];

    // Fetch in parallel batches of 10 for speed
    const batchSize = 10;
    for (int start = 0; start < messages.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, messages.length);
      final batch = messages.sublist(start, end);

      final futures = batch.map((msgRef) async {
        try {
          final msg = await api.users.messages.get('me', msgRef.id!, format: 'full');
          return _parseMessage(msg);
        } catch (_) {
          return null;
        }
      });

      final batchResults = await Future.wait(futures);
      for (final r in batchResults) {
        if (r != null && !_isDuplicate(r)) {
          results.add(r);
        }
      }
    }

    return results;
  }

  SmsParseResult? _parseMessage(gmail.Message msg) {
    final headers = msg.payload?.headers ?? [];

    String? subject;
    String? from;
    DateTime? date;

    for (final h in headers) {
      switch (h.name?.toLowerCase()) {
        case 'subject':
          subject = h.value;
          break;
        case 'from':
          from = h.value;
          break;
        case 'date':
          if (h.value != null) {
            date = _parseEmailDate(h.value!);
          }
          break;
      }
    }

    date ??= msg.internalDate != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(msg.internalDate!))
        : DateTime.now();

    final body = _extractBody(msg.payload);
    if (body == null || body.isEmpty) return null;

    return GmailParser.parse(
      body: body,
      sender: from,
      subject: subject,
      date: date,
    );
  }

  /// Extract email body text from message payload (handles multipart).
  String? _extractBody(gmail.MessagePart? payload) {
    if (payload == null) return null;

    // Direct body
    if (payload.body?.data != null && payload.body!.data!.isNotEmpty) {
      return _decodeBase64(payload.body!.data!);
    }

    // Multipart — prefer text/html, fallback to text/plain
    final parts = payload.parts;
    if (parts == null) return null;

    String? html;
    String? plain;

    for (final part in parts) {
      final mime = part.mimeType?.toLowerCase() ?? '';
      if (mime == 'text/html' && part.body?.data != null) {
        html = _decodeBase64(part.body!.data!);
      } else if (mime == 'text/plain' && part.body?.data != null) {
        plain = _decodeBase64(part.body!.data!);
      } else if (mime.startsWith('multipart/')) {
        // Recurse into nested multipart
        final nested = _extractBody(part);
        if (nested != null) return nested;
      }
    }

    return html ?? plain;
  }

  String _decodeBase64(String data) {
    // Gmail uses URL-safe base64
    final normalized = data.replaceAll('-', '+').replaceAll('_', '/');
    return utf8.decode(base64.decode(normalized));
  }

  DateTime? _parseEmailDate(String dateStr) {
    try {
      // Email dates: "Tue, 18 Mar 2026 10:30:00 +0530"
      // Remove day name prefix if present
      final cleaned = dateStr.replaceFirst(RegExp(r'^[A-Za-z]{3},\s*'), '');
      return DateTime.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  bool _isDuplicate(SmsParseResult result) {
    return _pending.any((p) =>
        p.amount == result.amount &&
        p.rawMessage == result.rawMessage &&
        p.dateTime == result.dateTime);
  }

  Future<Transaction> confirmTransaction(SmsParseResult result) async {
    final PaidVia? paidVia;
    if (result.isCredit) {
      paidVia = result.isCreditCard ? PaidVia.creditCard : null;
    } else {
      paidVia = result.isCreditCard ? PaidVia.creditCard : PaidVia.bank;
    }

    final TransactionType type;
    if (result.isCredit && result.isCreditCard) {
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
