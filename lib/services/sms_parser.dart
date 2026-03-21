/// Parses Indian bank SMS messages to extract transaction details.
class SmsParseResult {
  final double amount;
  final bool isCredit;
  final bool isCreditCard;
  final String? bankName;
  final String? accountLast4;
  final String? upiId;
  final String rawMessage;
  final DateTime dateTime;

  SmsParseResult({
    required this.amount,
    required this.isCredit,
    this.isCreditCard = false,
    this.bankName,
    this.accountLast4,
    this.upiId,
    required this.rawMessage,
    required this.dateTime,
  });

  String get label {
    final type = isCredit ? 'Credited' : 'Debited';
    final bank = bankName != null ? ' via $bankName' : '';
    final acct = accountLast4 != null ? ' (A/c $accountLast4)' : '';
    return '$type$bank$acct';
  }
}

class SmsParser {
  // ── Unicode Normalization ──
  // Bank SMS often use bold/italic/styled Unicode characters.
  // We normalize them to plain ASCII before parsing.

  static String normalize(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      buf.write(_normalizeRune(rune));
    }
    return buf.toString();
  }

  static String _normalizeRune(int r) {
    // Mathematical Bold A-Z / a-z
    if (r >= 0x1D400 && r <= 0x1D419) return String.fromCharCode(0x41 + r - 0x1D400);
    if (r >= 0x1D41A && r <= 0x1D433) return String.fromCharCode(0x61 + r - 0x1D41A);
    // Mathematical Bold 0-9
    if (r >= 0x1D7CE && r <= 0x1D7D7) return String.fromCharCode(0x30 + r - 0x1D7CE);
    // Mathematical Italic A-Z / a-z
    if (r >= 0x1D434 && r <= 0x1D44D) return String.fromCharCode(0x41 + r - 0x1D434);
    if (r >= 0x1D44E && r <= 0x1D467) return String.fromCharCode(0x61 + r - 0x1D44E);
    // Mathematical Bold Italic A-Z / a-z
    if (r >= 0x1D468 && r <= 0x1D481) return String.fromCharCode(0x41 + r - 0x1D468);
    if (r >= 0x1D482 && r <= 0x1D49B) return String.fromCharCode(0x61 + r - 0x1D482);
    // Sans-Serif A-Z / a-z
    if (r >= 0x1D5A0 && r <= 0x1D5B9) return String.fromCharCode(0x41 + r - 0x1D5A0);
    if (r >= 0x1D5BA && r <= 0x1D5D3) return String.fromCharCode(0x61 + r - 0x1D5BA);
    // Sans-Serif Bold A-Z / a-z / 0-9
    if (r >= 0x1D5D4 && r <= 0x1D5ED) return String.fromCharCode(0x41 + r - 0x1D5D4);
    if (r >= 0x1D5EE && r <= 0x1D607) return String.fromCharCode(0x61 + r - 0x1D5EE);
    if (r >= 0x1D7EC && r <= 0x1D7F5) return String.fromCharCode(0x30 + r - 0x1D7EC);
    // Sans-Serif Bold Italic A-Z / a-z
    if (r >= 0x1D608 && r <= 0x1D621) return String.fromCharCode(0x41 + r - 0x1D608);
    if (r >= 0x1D622 && r <= 0x1D63B) return String.fromCharCode(0x61 + r - 0x1D622);
    // Monospace A-Z / a-z / 0-9
    if (r >= 0x1D670 && r <= 0x1D689) return String.fromCharCode(0x41 + r - 0x1D670);
    if (r >= 0x1D68A && r <= 0x1D6A3) return String.fromCharCode(0x61 + r - 0x1D68A);
    if (r >= 0x1D7F6 && r <= 0x1D7FF) return String.fromCharCode(0x30 + r - 0x1D7F6);
    // Double-Struck 0-9
    if (r >= 0x1D7D8 && r <= 0x1D7E1) return String.fromCharCode(0x30 + r - 0x1D7D8);
    // Fullwidth A-Z / a-z / 0-9
    if (r >= 0xFF21 && r <= 0xFF3A) return String.fromCharCode(0x41 + r - 0xFF21);
    if (r >= 0xFF41 && r <= 0xFF5A) return String.fromCharCode(0x61 + r - 0xFF41);
    if (r >= 0xFF10 && r <= 0xFF19) return String.fromCharCode(0x30 + r - 0xFF10);
    return String.fromCharCode(r);
  }

  // ── Known bank sender substrings ──
  static const _knownBankSenders = [
    'SBI', 'HDFC', 'ICICI', 'AXIS', 'KOTAK', 'KOTK',
    'PNB', 'PUNB', 'BOI', 'CAN', 'UCO', 'CENT',
    'YES', 'IDFC', 'PAYTM', 'JUP', 'JIOBNK',
    'AUBANK', 'AUSFBL',
    'GPAY', 'PHONEPE', 'PYTM',
    'INDBNK', 'IABO', 'FIBNK', 'SLCBNK',
    'FEDER', 'BANDH', 'INDUS', 'BOBSMS', 'BARODA',
    'UNION', 'MAHBNK', 'SYNBNK', 'RBLBNK',
    'SBM',
  ];

  /// Check if an SMS sender looks like a bank.
  /// Indian bank senders: XX-SBIBNK, AX-AUBANK-S, CP-AXISBK-S, VM-HDFCBK, etc.
  static bool isBankSender(String? sender) {
    if (sender == null || sender.isEmpty) return false;
    final s = normalize(sender).toUpperCase();
    // Strip common prefixes like "XX-" and suffixes like "-S"
    final stripped = s.replaceAll(RegExp(r'^[A-Z]{2}-'), '').replaceAll(RegExp(r'-[A-Z]$'), '');
    // Check against known bank substrings
    for (final bank in _knownBankSenders) {
      if (stripped.contains(bank)) return true;
    }
    // Fallback: sender is 2-letter prefix + dash + 4+ uppercase letters
    if (RegExp(r'^[A-Z]{2}-[A-Z]{4,}').hasMatch(s)) return true;
    return false;
  }

  /// Amount patterns
  static final _amountPatterns = [
    RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'([\d,]+\.?\d*)\s*(?:Rs\.?|INR|₹)', caseSensitive: false),
  ];

  static final _creditCardPattern = RegExp(
    r'credit\s*card',
    caseSensitive: false,
  );

  static final _debitKeywords = RegExp(
    r'debit|debited|withdrawn|sent|paid|purchase|spent|transferred|txn\s*of|payment\s*of|has\s+been\s+used',
    caseSensitive: false,
  );

  static final _creditKeywords = RegExp(
    r'credited|received|deposited|refund|cashback|added|reversed',
    caseSensitive: false,
  );

  static final _accountPattern = RegExp(
    r'(?:a/?c|acct?|account)\s*(?:no\.?\s*)?[xX*]*(\d{4,6})',
    caseSensitive: false,
  );

  static final _upiPattern = RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z]{2,})');

  /// Try to parse a bank SMS. Returns null if not a valid transaction SMS.
  static SmsParseResult? parse(String body, {String? sender, DateTime? date}) {
    if (body.isEmpty) return null;

    // Normalize styled Unicode to plain ASCII
    final text = normalize(body);

    // Extract amount
    double? amount;
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)?.replaceAll(',', '');
        if (raw != null) {
          amount = double.tryParse(raw);
          if (amount != null && amount > 0) break;
        }
      }
    }
    if (amount == null || amount <= 0) return null;

    // Detect credit card mention
    final isCreditCard = _creditCardPattern.hasMatch(text);

    // Strip "credit card" from text before checking debit/credit keywords
    // so "Credit card" doesn't falsely trigger credit detection
    final textForKeywords = text.replaceAll(_creditCardPattern, ' ');

    // Determine debit or credit
    final hasDebit = _debitKeywords.hasMatch(textForKeywords);
    final hasCredit = _creditKeywords.hasMatch(textForKeywords);
    if (!hasDebit && !hasCredit) return null;

    bool isCredit;
    if (hasDebit && hasCredit) {
      final debitPos = _debitKeywords.firstMatch(textForKeywords)!.start;
      final creditPos = _creditKeywords.firstMatch(textForKeywords)!.start;
      isCredit = creditPos < debitPos;
    } else {
      isCredit = hasCredit;
    }

    // Extract account number
    String? accountLast4;
    final acctMatch = _accountPattern.firstMatch(text);
    if (acctMatch != null) accountLast4 = acctMatch.group(1);

    // Extract UPI ID
    String? upiId;
    final upiMatch = _upiPattern.firstMatch(text);
    if (upiMatch != null) upiId = upiMatch.group(1);

    // Bank name from sender, then fallback to body
    String? bankName;
    if (sender != null) {
      final clean = normalize(sender).replaceAll(RegExp(r'^[A-Z]{2}-'), '');
      bankName = _bankNameFromSender(clean);
    }
    bankName ??= _bankNameFromBody(text);

    return SmsParseResult(
      amount: amount,
      isCredit: isCredit,
      isCreditCard: isCreditCard,
      bankName: bankName,
      accountLast4: accountLast4,
      upiId: upiId,
      rawMessage: body,
      dateTime: date ?? DateTime.now(),
    );
  }

  static String? _bankNameFromSender(String sender) {
    final s = sender.toUpperCase();
    if (s.contains('SBI')) return 'SBI';
    if (s.contains('HDFC')) return 'HDFC';
    if (s.contains('ICICI')) return 'ICICI';
    if (s.contains('AXIS')) return 'Axis';
    if (s.contains('KOTAK') || s.contains('KOTK')) return 'Kotak';
    if (s.contains('PNB') || s.contains('PUNB')) return 'PNB';
    if (s.contains('BOI')) return 'BOI';
    if (s.contains('CAN')) return 'Canara';
    if (s.contains('IABO')) return 'IOB';
    if (s.contains('UCO')) return 'UCO';
    if (s.contains('IND')) return 'Indian Bank';
    if (s.contains('CENT')) return 'Central Bank';
    if (s.contains('YES')) return 'Yes Bank';
    if (s.contains('IDFC')) return 'IDFC First';
    if (s.contains('PAYTM')) return 'Paytm';
    if (s.contains('JUP')) return 'Jupiter';
    if (s.contains('FI')) return 'Fi';
    if (s.contains('JIO')) return 'Jio';
    if (s.contains('AU')) return 'AU Bank';
    if (s.contains('SBM')) return 'SBM';
    return null;
  }

  static String? _bankNameFromBody(String text) {
    final t = text.toUpperCase();
    if (t.contains('AU BANK') || t.contains('AU SMALL FINANCE')) return 'AU Bank';
    if (t.contains('SBI') || t.contains('STATE BANK')) return 'SBI';
    if (t.contains('HDFC')) return 'HDFC';
    if (t.contains('ICICI')) return 'ICICI';
    if (t.contains('AXIS')) return 'Axis';
    if (t.contains('KOTAK')) return 'Kotak';
    if (t.contains('PNB') || t.contains('PUNJAB NATIONAL')) return 'PNB';
    if (t.contains('BOB') || t.contains('BANK OF BARODA')) return 'BOB';
    if (t.contains('CANARA')) return 'Canara';
    if (t.contains('UNION BANK')) return 'Union Bank';
    if (t.contains('IDFC')) return 'IDFC First';
    if (t.contains('YES BANK')) return 'Yes Bank';
    if (t.contains('FEDERAL BANK')) return 'Federal Bank';
    if (t.contains('BANDHAN')) return 'Bandhan';
    if (t.contains('INDUSIND')) return 'IndusInd';
    return null;
  }
}
