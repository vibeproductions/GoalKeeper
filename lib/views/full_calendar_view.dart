// lib/views/full_calendar_view.dart
// Upcoming countdown page — deadlines grouped by time bracket

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper_flutter/store/goal_store.dart';
import 'package:goalkeeper_flutter/models/models.dart';
import 'package:goalkeeper_flutter/theme/app_theme.dart';

class FullCalendarView extends StatefulWidget {
  const FullCalendarView({super.key});

  @override
  State<FullCalendarView> createState() => _FullCalendarViewState();
}

class _FullCalendarViewState extends State<FullCalendarView> {
  DeadlineKind? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final store     = context.watch<GoalStore>();
    final deadlines = store.allUpcomingDeadlines;
    final filtered  = _filter == null
        ? deadlines
        : deadlines.where((d) => d.kind == _filter).toList();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _header(store),
          _filterBar,
          Expanded(
            child: filtered.isEmpty
                ? _empty
                : ListView(
                    padding: const EdgeInsets.all(14),
                    children: _buildGroups(filtered, store),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(GoalStore store) {
    final all  = store.allUpcomingDeadlines;
    final next = all.isNotEmpty ? all.first : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upcoming',
                    style: AppText.display(22, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${all.length} items ahead',
                    style: AppText.body(11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (next != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Next up',
                    style: AppText.label(9, color: AppColors.textTertiary)),
                Text(
                  next.daysUntil == 0 ? 'Today' : 'in ${next.daysUntil}d',
                  style: AppText.display(14,
                      weight: FontWeight.w700,
                      color: next.daysUntil <= 2 ? AppColors.danger : next.color),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget get _filterBar => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Row(
          children: [
            _filterChip('All', null),
            _filterChip('Goals', DeadlineKind.goal),
            _filterChip('Assignments', DeadlineKind.scheduleItem),
            _filterChip('Events', DeadlineKind.event),
          ],
        ),
      );

  Widget _filterChip(String label, DeadlineKind? kind) {
    final active = _filter == kind;
    return GestureDetector(
      onTap: () => setState(() => _filter = kind),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(label,
            style: AppText.body(12,
                weight: FontWeight.w600,
                color: active ? Colors.black : AppColors.textSecondary)),
      ),
    );
  }

  List<Widget> _buildGroups(List<AnyDeadline> deadlines, GoalStore store) {
    final today     = deadlines.where((d) => d.daysUntil == 0).toList();
    final thisWeek  = deadlines.where((d) => d.daysUntil > 0 && d.daysUntil <= 7).toList();
    final thisMonth = deadlines.where((d) => d.daysUntil > 7 && d.daysUntil <= 30).toList();
    final later     = deadlines.where((d) => d.daysUntil > 30).toList();

    final widgets = <Widget>[];
    if (today.isNotEmpty)     widgets.addAll(_group('Today', today, urgent: true, store: store));
    if (thisWeek.isNotEmpty)  widgets.addAll(_group('This Week', thisWeek, store: store));
    if (thisMonth.isNotEmpty) widgets.addAll(_group('This Month', thisMonth, store: store));
    if (later.isNotEmpty)     widgets.addAll(_group('Later', later, store: store));
    return widgets;
  }

  List<Widget> _group(String label, List<AnyDeadline> items,
      {bool urgent = false, required GoalStore store}) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          children: [
            Text(label.toUpperCase(),
                style: AppText.label(10,
                    color: urgent ? AppColors.danger : AppColors.textTertiary)),
            if (urgent) ...[
              const SizedBox(width: 5),
              Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
      ...items.map((d) => _card(d, store)),
    ];
  }

  Widget _card(AnyDeadline deadline, GoalStore store) => GestureDetector(
        onTap: () {
          switch (deadline.kind) {
            case DeadlineKind.goal:
              store.selectGoal(deadline.id);
            case DeadlineKind.scheduleItem:
              store.selectScheduleItem(deadline.id);
            case DeadlineKind.event:
              store.selectEvent(deadline.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: deadline.daysUntil == 0
                  ? deadline.color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: deadline.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(deadline.icon, size: 18, color: deadline.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deadline.title,
                        style: AppText.body(13, weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(deadline.subtitle,
                            style: AppText.body(11, color: AppColors.textSecondary)),
                        Text(' · ', style: AppText.body(11, color: AppColors.textTertiary)),
                        Text(
                          '${deadline.date.month}/${deadline.date.day}/${deadline.date.year}',
                          style: AppText.body(11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _badge(deadline.daysUntil, deadline.color),
            ],
          ),
        ),
      );

  Widget _badge(int days, Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (days == 0)
            Text('TODAY',
                style: AppText.label(10, color: AppColors.danger))
          else ...[
            Text('$days',
                style: AppText.mono(20,
                    weight: FontWeight.w700,
                    color: days <= 3
                        ? AppColors.danger
                        : days <= 7
                            ? AppColors.warning
                            : color)),
            Text(days == 1 ? 'day' : 'days',
                style: AppText.body(9, color: AppColors.textTertiary)),
          ],
        ],
      );

  Widget get _empty => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_rounded,
                size: 36, color: AppColors.accent),
            const SizedBox(height: 12),
            Text('Nothing coming up',
                style: AppText.display(15,
                    weight: FontWeight.w600, color: AppColors.textTertiary)),
            const SizedBox(height: 6),
            Text('Add goals, assignments, or calendar events.',
                style: AppText.body(12, color: AppColors.textDisabled),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
