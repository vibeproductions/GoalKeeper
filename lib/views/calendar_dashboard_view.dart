// lib/views/calendar_dashboard_view.dart
// Middle column: Month grid + Upcoming countdown tab

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/theme/app_theme.dart';
import 'package:goalkeeper/widgets/progress_ring.dart';
import 'package:goalkeeper/views/full_calendar_view.dart';

class CalendarDashboardView extends StatefulWidget {
  const CalendarDashboardView({super.key});

  @override
  State<CalendarDashboardView> createState() => _CalendarDashboardViewState();
}

class _CalendarDashboardViewState extends State<CalendarDashboardView> {
  int _tab = 0; // 0 = Month, 1 = Upcoming
  DateTime _currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _tabBar,
          Expanded(
            child: _tab == 0 ? _monthView : const FullCalendarView(),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────
  Widget get _tabBar => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            _tab_('Month',    Icons.calendar_month_rounded, 0),
            _tab_('Upcoming', Icons.access_time_rounded,    1),
          ],
        ),
      );

  Widget _tab_(String label, IconData icon, int idx) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 13,
                      color: active ? AppColors.accent : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(label,
                      style: AppText.body(12,
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? AppColors.accent : AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              height: 2,
              color: active ? AppColors.accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  // ── Month view ─────────────────────────────────────────────────────────────
  Widget get _monthView {
    final store = context.watch<GoalStore>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _monthHeader,
        const SizedBox(height: 16),
        _summaryRings(store),
        const SizedBox(height: 16),
        _calendarGrid(store),
        const SizedBox(height: 16),
        _dueThisMonth(store),
      ],
    );
  }

  Widget get _monthHeader {
    final months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    final days   = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    final now    = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${months[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: AppText.display(22, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}',
                  style: AppText.body(11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        // Month nav
        Row(children: [
          _navBtn(Icons.chevron_left, () => setState(() =>
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1))),
          const SizedBox(width: 4),
          _navBtn(Icons.chevron_right, () => setState(() =>
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1))),
        ]),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.textSecondary),
        ),
      );

  Widget _summaryRings(GoalStore store) {
    final avg = store.activeGoals.isEmpty
        ? 0.0
        : store.activeGoals.map((g) => g.progress).reduce((a, b) => a + b) /
            store.activeGoals.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Overall card
          _ringCard(
            ring: Stack(
              alignment: Alignment.center,
              children: [
                ProgressRing(progress: avg, color: AppColors.accent, strokeWidth: 8, size: 52),
                Text('${(avg * 100).toInt()}%',
                    style: AppText.mono(11, weight: FontWeight.w700)),
              ],
            ),
            label: 'Overall',
          ),
          ...store.activeGoals.take(3).map((goal) => GestureDetector(
                onTap: () => store.selectGoal(goal.id),
                child: _ringCard(
                  ring: Stack(
                    alignment: Alignment.center,
                    children: [
                      ProgressRing(
                          progress: goal.progress, color: goal.type.color,
                          strokeWidth: 8, size: 52),
                      Icon(goal.type.icon, size: 13, color: goal.type.color),
                    ],
                  ),
                  label: goal.title,
                  selected: store.selectedGoalID == goal.id,
                  borderColor: goal.type.color,
                ),
              )),
        ],
      ),
    );
  }

  Widget _ringCard({required Widget ring, required String label,
      bool selected = false, Color? borderColor}) =>
      Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected && borderColor != null
                ? borderColor.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            ring,
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(label,
                  style: AppText.body(10, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );

  // ── Calendar grid ──────────────────────────────────────────────────────────
  Widget _calendarGrid(GoalStore store) {
    final goalMap     = store.goalsForMonth(_currentMonth);
    final scheduleMap = store.scheduleForMonth(_currentMonth);
    final eventMap    = store.eventsForMonth(_currentMonth);

    final firstDay  = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
        _currentMonth.year, _currentMonth.month);
    final startOffset = firstDay.weekday % 7; // Sunday = 0

    final cells = <DateTime?>[
      ...List.filled(startOffset, null),
      ...List.generate(daysInMonth, (i) =>
          DateTime(_currentMonth.year, _currentMonth.month, i + 1)),
    ];
    // Pad to complete weeks
    while (cells.length % 7 != 0) cells.add(null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Day labels
          Row(
            children: ['Su','Mo','Tu','We','Th','Fr','Sa'].map((d) =>
                Expanded(
                  child: Text(d,
                      style: AppText.body(10, weight: FontWeight.w500,
                          color: AppColors.textTertiary),
                      textAlign: TextAlign.center),
                )).toList(),
          ),
          const SizedBox(height: 4),
          // Day cells
          ...List.generate(cells.length ~/ 7, (row) => Row(
            children: List.generate(7, (col) {
              final date = cells[row * 7 + col];
              if (date == null) return const Expanded(child: SizedBox(height: 36));
              final isToday    = DateUtils.isSameDay(date, DateTime.now());
              final isSelected = DateUtils.isSameDay(date, store.selectedDate);
              final day        = DateTime(date.year, date.month, date.day);
              final dots = [
                ...((goalMap[day] ?? []).take(2).map((g) => g.type.color)),
                ...((scheduleMap[day] ?? []).take(2).map((i) => i.type.color)),
                ...((eventMap[day] ?? []).take(1).map((e) => e.color.color)),
              ];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    store.selectedDate = date;
                    (context as Element).markNeedsBuild();
                  },
                  child: SizedBox(
                    height: 36,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.accent
                                : isSelected
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: AppText.body(12,
                                  weight: isToday ? FontWeight.w700 : FontWeight.w400,
                                  color: isToday ? Colors.black : AppColors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots.take(4).map((c) => Container(
                            width: 3.5, height: 3.5,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          )),
        ],
      ),
    );
  }

  // ── Due this month list ────────────────────────────────────────────────────
  Widget _dueThisMonth(GoalStore store) {
    final sorted = [...store.goals]
      ..sort((a, b) {
        final da = a.dueDate ?? a.createdDate;
        final db = b.dueDate ?? b.createdDate;
        return da.compareTo(db);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Due This Month',
            style: AppText.body(13, weight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Text('No goals yet — use the + menu to add one',
              style: AppText.body(12, color: AppColors.textDisabled))
        else
          ...sorted.map((goal) => GestureDetector(
                onTap: () => store.selectGoal(goal.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: store.selectedGoalID == goal.id &&
                            store.detailSelection == DetailSelection.goal
                        ? Colors.white.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: goal.type.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.title,
                                style: AppText.body(12, weight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                            if (goal.daysUntilDue != null)
                              Text(
                                goal.daysUntilDue! < 0
                                    ? 'Overdue ${-goal.daysUntilDue!}d'
                                    : 'Due in ${goal.daysUntilDue}d',
                                style: AppText.body(10,
                                    color: goal.daysUntilDue! < 0
                                        ? AppColors.danger
                                        : AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      MiniRingView(
                          progress: goal.progress, color: goal.type.color, size: 24),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
