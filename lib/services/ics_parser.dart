// lib/services/ics_parser.dart
// ICS calendar file parser — translated from Swift ICSParser struct

import 'package:goalkeeper/models/models.dart';

class ICSParser {
  static (List<CalendarEvent>, String) parse(String content) {
    final lines = content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trimRight())
        .toList();

    // Unfold continued lines (RFC 5545 line folding)
    final unfolded = <String>[];
    for (final line in lines) {
      if ((line.startsWith(' ') || line.startsWith('\t')) && unfolded.isNotEmpty) {
        unfolded[unfolded.length - 1] += line.substring(1);
      } else {
        unfolded.add(line);
      }
    }

    // Extract calendar name
    var calendarName = '';
    for (final line in unfolded) {
      if (line.toUpperCase().startsWith('X-WR-CALNAME:')) {
        calendarName = line.substring('X-WR-CALNAME:'.length).trim();
      }
    }

    // Parse VEVENT blocks
    var inEvent = false;
    var current = <String, String>{};
    final events = <CalendarEvent>[];

    for (final line in unfolded) {
      final upper = line.toUpperCase();
      if (upper == 'BEGIN:VEVENT') {
        inEvent = true;
        current = {};
      } else if (upper == 'END:VEVENT') {
        inEvent = false;
        final event = _buildEvent(current, calendarName);
        if (event != null) events.add(event);
      } else if (inEvent) {
        final colonIdx = line.indexOf(':');
        if (colonIdx == -1) continue;
        final keyPart = line.substring(0, colonIdx);
        final value   = line.substring(colonIdx + 1);
        // Take just the property name (before any semicolons)
        final key = keyPart.split(';').first.toUpperCase();
        current[key] = value;
      }
    }

    // Filter to upcoming/recent, sort by date
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final filtered = events
        .where((e) => e.startDate.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return (filtered, calendarName);
  }

  static CalendarEvent? _buildEvent(Map<String, String> props, String calName) {
    final summary = props['SUMMARY'];
    if (summary == null || summary.isEmpty) return null;

    final startDate = _parseDate(props['DTSTART'] ?? '');
    if (startDate == null) return null;

    final endDate = _parseDate(props['DTEND'] ?? '');
    final isAllDay = (props['DTSTART'] ?? '').length == 8 ||
        (props['DTSTART'] ?? '').contains('VALUE=DATE');

    final notes = (props['DESCRIPTION'] ?? '')
        .replaceAll('\\n', '\n')
        .replaceAll('\\,', ',');

    return CalendarEvent(
      title:        summary.replaceAll('\\,', ','),
      notes:        notes,
      startDate:    startDate,
      endDate:      endDate,
      isAllDay:     isAllDay,
      color:        CalendarEventColor.blue,
      source:       CalendarEventSource.ics,
      calendarName: calName,
    );
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final clean = raw.replaceAll('Z', '').trim();
    // yyyyMMdd'T'HHmmss
    if (clean.length >= 15 && clean.contains('T')) {
      try {
        final y = int.parse(clean.substring(0, 4));
        final m = int.parse(clean.substring(4, 6));
        final d = int.parse(clean.substring(6, 8));
        final h = int.parse(clean.substring(9, 11));
        final min = int.parse(clean.substring(11, 13));
        final s = int.parse(clean.substring(13, 15));
        return DateTime(y, m, d, h, min, s);
      } catch (_) {}
    }
    // yyyyMMdd (all-day)
    if (clean.length >= 8) {
      try {
        final y = int.parse(clean.substring(0, 4));
        final m = int.parse(clean.substring(4, 6));
        final d = int.parse(clean.substring(6, 8));
        return DateTime(y, m, d);
      } catch (_) {}
    }
    return null;
  }
}
