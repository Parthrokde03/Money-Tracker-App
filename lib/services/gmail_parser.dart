import 'sms_parser.dart';

/// Parses bank transaction emails from Gmail.
/// Bank emails typically contain the same keywords as SMS
/// (credited, debited, Rs., INR, etc.) so we reuse SmsParser logic.
class GmailParser {
  /// Strip HTML tags and decode common entities to get plain text.
  static String _stripHtml(String html) {
    var text = html.replaceAll(
      RegExp(r'<(style|script)[^>]*>.*?</\1>',
          caseSensitive: false, dotAll: true),
      ' ',
    );
    text = text.replaceAll(
      RegExp(r'<(br|/p|/div|/tr|/li)[^>]*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#8377;', '₹');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Try to parse a bank email body. Returns null if not a transaction email.
  static SmsParseResult? parse({
    required String body,
    String? sender,
    String? subject,
    DateTime? date,
  }) {
    final plainBody = _stripHtml(body);
    final combined = subject != null ? '$subject\n$plainBody' : plainBody;
    final result = SmsParser.parse(combined, sender: sender, date: date);
    if (result == null) return null;

    final displayText = plainBody.length > 200
        ? '${plainBody.substring(0, 200)}...'
        : plainBody;

    return SmsParseResult(
      amount: result.amount,
      isCredit: result.isCredit,
      isCreditCard: result.isCreditCard,
      bankName: result.bankName,
      accountLast4: result.accountLast4,
      upiId: result.upiId,
      rawMessage: displayText,
      dateTime: result.dateTime,
    );
  }
}
