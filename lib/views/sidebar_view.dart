// lib/views/sidebar_view.dart
// Left sidebar — goals list + grouped schedule subjects

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/theme/app_theme.dart';
import 'package:goalkeeper/widgets/progress_ring.dart';

class SidebarView extends StatefulWidget {
  final VoidCallback onAddGoal;
  final VoidCallback onImportSchedule;
  final VoidCallback onImportCalendar;

  const SidebarView({
    super.key,
    required this.onAddGoal,
    required this.onImportSchedule,
    required this.onImportCalendar,
  });

  @override
  State<SidebarView> createState() => _SidebarViewState();
}

class _SidebarViewState extends State<SidebarView> {
  final Set<String> _expandedSubjects = {};

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalStore>();

    // Auto-expand new subjects
    for (final s in store.subjects) {
      _expandedSubjects.add(s);
    }

    return Container(
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          _header(store),
          if (store.overdueGoals.isNotEmpty) _overdueBar(store),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                _goalsSection(store),
                if (store.scheduleItems.isNotEmpty) ...[
                  _sectionLabel('Schedule'),
                  ...store.subjects.map((s) => _subjectGroup(store, s)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _header(GoalStore store) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GoalKeeper',
                    style: AppText.display(20, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${store.activeGoals.length} goals · '
                  '${store.scheduleItems.where((i) => !i.isCompleted).length} assignments',
                  style: AppText.body(11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          // Dropdown + button
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_rounded,
                size: 22, color: AppColors.accent),
            color: AppColors.sidebarBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            onSelected: (value) {
              switch (value) {
                case 'goal':
                  widget.onAddGoal();
                case 'schedule':
                  widget.onImportSchedule();
                case 'calendar':
                  widget.onImportCalendar();
              }
            },
            itemBuilder: (_) => [
              _menuItem('goal', Icons.star_rounded, 'New Goal'),
              _menuItem(
                  'schedule', Icons.calendar_month_rounded, 'Import Schedule'),
              _menuItem('calendar', Icons.calendar_today_rounded,
                  'Import Calendar (.ics)'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 10),
          Text(label, style: AppText.body(13)),
        ]),
      );

  // ── Overdue bar ────────────────────────────────────────────────────────────
  Widget _overdueBar(GoalStore store) => Container(
        color: AppColors.danger.withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 13, color: AppColors.danger),
            const SizedBox(width: 6),
            Text('${store.overdueGoals.length} overdue',
                style: AppText.body(11,
                    weight: FontWeight.w600, color: AppColors.danger)),
          ],
        ),
      );

  // ── Goals section ──────────────────────────────────────────────────────────
  Widget _goalsSection(GoalStore store) {
    if (store.goals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 24, color: AppColors.accent),
              const SizedBox(height: 8),
              Text('No goals yet',
                  style: AppText.body(12, color: AppColors.textTertiary)),
              TextButton(
                onPressed: widget.onAddGoal,
                child: Text('Add First Goal',
                    style: AppText.body(11,
                        weight: FontWeight.w600, color: AppColors.accent)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Goals'),
        ...store.activeGoals.map((g) => _GoalRow(goal: g)),
        if (store.completedGoals.isNotEmpty) ...[
          _subSectionLabel('Completed'),
          ...store.completedGoals.map((g) => _GoalRow(goal: g)),
        ],
      ],
    );
  }

  // ── Subject group ──────────────────────────────────────────────────────────
  Widget _subjectGroup(GoalStore store, String subject) {
    final items = store.itemsForSubject(subject);
    final isExpanded = _expandedSubjects.contains(subject);
    final overdue = items.where((i) => i.isOverdue).length;
    final upcoming = items.where((i) => !i.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          // Subject header
          InkWell(
            onTap: () => setState(() {
              if (isExpanded)
                _expandedSubjects.remove(subject);
              else
                _expandedSubjects.add(subject);
            }),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(subject,
                        style: AppText.body(12, weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (overdue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('$overdue overdue',
                          style: AppText.body(9,
                              weight: FontWeight.w700,
                              color: AppColors.danger)),
                    )
                  else
                    Text('$upcoming',
                        style: AppText.body(10, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ),
          if (isExpanded) ...items.map((item) => _ScheduleRow(item: item)),
        ],
      ),
    );
  }

  // ── Section labels ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 2),
        child: Text(title.toUpperCase(), style: AppText.label(10)),
      );

  Widget _subSectionLabel(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 1),
        child: Text(title.toUpperCase(),
            style: AppText.label(9, color: AppColors.textDisabled)),
      );
}

// ─── Goal Row ─────────────────────────────────────────────────────────────────

class _GoalRow extends StatelessWidget {
  final Goal goal;
  const _GoalRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalStore>();
    final isSelected = store.selectedGoalID == goal.id &&
        store.detailSelection == DetailSelection.goal;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => store.selectGoal(goal.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected
                ? goal.type.color.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            MiniRingView(
                progress: goal.progress, color: goal.type.color, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                      style: AppText.body(13, weight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(goal.type.icon,
                          size: 9, color: goal.type.color.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        goal.daysUntilDue != null
                            ? (goal.daysUntilDue! < 0
                                ? 'Overdue'
                                : '${goal.daysUntilDue}d left')
                            : goal.type.label,
                        style: AppText.body(10,
                            color: goal.daysUntilDue != null &&
                                    goal.daysUntilDue! < 0
                                ? AppColors.danger
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: goal.priority.color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Row ─────────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  final ScheduleItem item;
  const _ScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalStore>();
    final isSelected = store.selectedScheduleItemID == item.id &&
        store.detailSelection == DetailSelection.scheduleItem;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => store.selectScheduleItem(item.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => store.toggleScheduleItem(item.id),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      item.isCompleted ? item.type.color : Colors.transparent,
                  border: Border.all(
                    color: item.isCompleted
                        ? item.type.color
                        : Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check, size: 9, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppText.body(12,
                        weight: FontWeight.w500,
                        color: item.isCompleted
                            ? AppColors.textTertiary
                            : AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                    // strikethrough if completed
                    // Note: Flutter applies decoration separately:
                  ),
                  Row(
                    children: [
                      Icon(item.type.icon,
                          size: 8, color: item.type.color.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(_dueDateLabel,
                          style: AppText.body(10,
                              color: item.isOverdue
                                  ? AppColors.danger
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _dueDateLabel {
    if (item.isCompleted) return 'Done';
    final d = item.daysUntilDue;
    if (d < 0) return 'Overdue ${-d}d';
    if (d == 0) return 'Due today';
    if (d == 1) return 'Due tomorrow';
    return 'Due in ${d}d';
  }
}
