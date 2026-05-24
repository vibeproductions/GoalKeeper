// lib/views/calendar_event_detail_view.dart
// Calendar event detail with live per-second countdown

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/theme/app_theme.dart';

class CalendarEventDetailView extends StatefulWidget {
  final CalendarEvent event;
  const CalendarEventDetailView({super.key, required this.event});
  @override
  State<CalendarEventDetailView> createState() => _CalendarEventDetailViewState();
}

class _CalendarEventDetailViewState extends State<CalendarEventDetailView> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalStore>();
    final event = store.calendarEvents.firstWhere(
      (e) => e.id == widget.event.id, orElse: () => widget.event);

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _toolbar(event, store),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _heroCard(event),
                if (!event.isPast) ...[
                  const SizedBox(height: 16),
                  _countdownCard(event),
                ],
                const SizedBox(height: 16),
                _detailsCard(event),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar(CalendarEvent event, GoalStore store) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.sidebarBg,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10,
                decoration: BoxDecoration(color: event.color.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(event.source == CalendarEventSource.ics
                ? 'IMPORTED EVENT' : 'MANUAL EVENT',
                style: AppText.label(10, color: event.color.color)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.danger),
              tooltip: 'Delete event',
              onPressed: () {
                store.deleteEvent(event.id);
              },
            ),
          ],
        ),
      );

  Widget _heroCard(CalendarEvent event) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: event.color.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: event.color.color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 12, height: 12,
                  decoration: BoxDecoration(
                      color: event.color.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(event.source == CalendarEventSource.ics
                  ? 'IMPORTED EVENT' : 'MANUAL EVENT',
                  style: AppText.label(10, color: event.color.color)),
              if (event.calendarName.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(event.calendarName,
                      style: AppText.body(11, color: AppColors.textSecondary)),
                ),
              ],
            ]),
            const SizedBox(height: 12),
            Text(event.title, style: AppText.display(24, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: event.color.color),
              const SizedBox(width: 6),
              Text(_dateRangeString(event),
                  style: AppText.body(13, weight: FontWeight.w500,
                      color: AppColors.textSecondary)),
            ]),
            if (event.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(event.notes,
                    style: AppText.body(13, color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      );

  Widget _countdownCard(CalendarEvent event) {
    final diff       = event.startDate.difference(_now);
    final totalSecs  = diff.inSeconds.clamp(0, double.maxFinite.toInt());
    final days       = totalSecs ~/ 86400;
    final hours      = (totalSecs % 86400) ~/ 3600;
    final minutes    = (totalSecs % 3600) ~/ 60;
    final seconds    = totalSecs % 60;
    final pulsing    = _now.second % 2 == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: event.color.color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(children: [
            Text('Countdown', style: AppText.display(13, weight: FontWeight.w700)),
            const Spacer(),
            AnimatedOpacity(
              opacity: pulsing ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 500),
              child: Container(width: 6, height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 5),
            Text('LIVE', style: AppText.label(9, color: AppColors.success)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (days > 0) ...[
                _countdownUnit(days, 'days'),
                _separator,
              ],
              _countdownUnit(hours, 'hrs'),
              _separator,
              _countdownUnit(minutes, 'min'),
              _separator,
              _countdownUnit(seconds, 'sec'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownUnit(int value, String label) => Column(
        children: [
          Text(value.toString().padLeft(2, '0'),
              style: AppText.mono(36, weight: FontWeight.w700)),
          Text(label, style: AppText.body(10, color: AppColors.textTertiary)),
        ],
      );

  Widget get _separator => Text(':',
      style: AppText.mono(28, weight: FontWeight.w700,
          color: AppColors.textDisabled));

  Widget _detailsCard(CalendarEvent event) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(children: [
          _row('Start', _fullDate(event.startDate), event.color.color),
          if (event.endDate != null) ...[
            const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
            _row('End', _fullDate(event.endDate!), AppColors.textSecondary),
          ],
          const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
          _row('All Day', event.isAllDay ? 'Yes' : 'No', AppColors.textSecondary),
          const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
          _row('Color', event.color.label, event.color.color),
          const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.divider),
          _row('Source', event.source.name, AppColors.textSecondary),
        ]),
      );

  Widget _row(String label, String value, Color valueColor) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Text(label, style: AppText.body(12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppText.body(12, weight: FontWeight.w600, color: valueColor)),
        ]),
      );

  String _dateRangeString(CalendarEvent event) {
    final start = _fullDate(event.startDate);
    if (event.endDate == null) return start;
    final end = _fullDate(event.endDate!);
    return start == end ? start : '$start → $end';
  }

  String _fullDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
