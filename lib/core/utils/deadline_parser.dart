import 'package:intl/intl.dart';

class DeadlineParser {
  static DateTime? parse(String? deadlineStr) {
    if (deadlineStr == null || deadlineStr.trim().isEmpty) return null;
    final trimmed = deadlineStr.trim();

    try {
      return DateTime.parse(trimmed);
    } catch (_) {}

    final formats = [
      'd MMM yyyy',
      'MMM d yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'd/M/yyyy',
      'M/d/yyyy',
      'dd.MM.yyyy',
    ];

    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(trimmed);
      } catch (_) {}
    }

    final parts = trimmed.split(RegExp(r'\s*/\s*'));
    final now = DateTime.now();

    for (final part in parts) {
      final clean = part.replaceAll(RegExp(r'\(.*?\)'), '').trim();
      if (clean.isEmpty) continue;

      for (final fmt in formats) {
        try {
          final date = DateFormat(fmt).parse(clean);
          if (date.isAfter(now.subtract(const Duration(days: 365)))) {
            return date;
          }
        } catch (_) {}
      }

      DateTime? extracted = _extractDayMonth(clean, now);
      if (extracted != null) return extracted;

      extracted = _extractMonthDay(clean, now);
      if (extracted != null) return extracted;
    }

    return null;
  }

  static DateTime? _extractDayMonth(String text, DateTime now) {
    final regex = RegExp(
      r'(\d{1,2})\s+(January|February|March|April|May|June|'
      r'July|August|September|October|November|December)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = _monthNumber(match.group(2)!);
    for (final year in [now.year, now.year + 1]) {
      try {
        final date = DateTime(year, month, day);
        if (date.isAfter(now.subtract(const Duration(days: 30)))) {
          return date;
        }
      } catch (_) {}
    }
    return null;
  }

  static DateTime? _extractMonthDay(String text, DateTime now) {
    final regex = RegExp(
      r'(January|February|March|April|May|June|'
      r'July|August|September|October|November|December)\s+(\d{1,2})',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;
    final month = _monthNumber(match.group(1)!);
    final day = int.parse(match.group(2)!);
    for (final year in [now.year, now.year + 1]) {
      try {
        final date = DateTime(year, month, day);
        if (date.isAfter(now.subtract(const Duration(days: 30)))) {
          return date;
        }
      } catch (_) {}
    }
    return null;
  }

  static int? remainingDays(String? deadlineStr) {
    final date = parse(deadlineStr);
    if (date == null) return null;
    return date.difference(DateTime.now()).inDays;
  }

  static String format(String? deadlineStr) {
    if (deadlineStr == null || deadlineStr.trim().isEmpty) return 'No Deadline';
    final date = parse(deadlineStr);
    if (date == null) return deadlineStr;
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Today';
    if (diff <= 7) return 'In $diff days';
    return DateFormat('d MMM yyyy').format(date);
  }

  static int _monthNumber(String month) {
    const months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    return months[month.toLowerCase()] ?? 1;
  }
}
