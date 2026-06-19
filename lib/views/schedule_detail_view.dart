// lib/views/schedule_detail_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/services/anthropic_service.dart';
import 'package:goalkeeper/theme/app_theme.dart';
import 'package:goalkeeper/views/study_guide_view.dart';

class ScheduleDetailView extends StatefulWidget {
  final ScheduleItem item;
  const ScheduleDetailView({super.key, required this.item});
  @override
  State<ScheduleDetailView> createState() => _ScheduleDetailViewState();
}

class _ScheduleDetailViewState extends State<ScheduleDetailView> {
  final Set<String> _expandedUpcoming = {};
  bool _generatingGuide = false;
  String? _guideError;

  bool get _shouldShowGuide {
    final title = widget.item.title.toLowerCase();
    return widget.item.type == ScheduleItemType.test ||
        widget.item.type == ScheduleItemType.quiz ||
        title.contains('review') ||
        title.contains('study') ||
        title.contains('exam');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalStore>();
    final item = store.scheduleItems
        .firstWhere((i) => i.id == widget.item.id, orElse: () => widget.item);
    final upcoming = store.upcomingItemsForSubject(item.subject, item.id);
    final guide = store.studyGuideFor(item.id);

    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _heroCard(item, store),
          const SizedBox(height: 16),
          if (_shouldShowGuide || guide != null) ...[
            _studyGuideSection(item, guide, store),
            const SizedBox(height: 16),
          ],
          if (upcoming.isNotEmpty) _upcomingSection(upcoming, store),
        ],
      ),
    );
  }

  Widget _heroCard(ScheduleItem item, GoalStore store) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.type.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: item.type.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: item.type.color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(item.subject.toUpperCase(),
                    style: AppText.label(10, color: item.type.color)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.type.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    Icon(item.type.icon, size: 11, color: item.type.color),
                    const SizedBox(width: 4),
                    Text(item.type.label,
                        style: AppText.body(11,
                            weight: FontWeight.w600, color: item.type.color)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.title,
                style: AppText.display(22, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13,
                  color: item.isOverdue
                      ? AppColors.danger
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(_dueDateString(item),
                  style: AppText.body(13,
                      weight: FontWeight.w500,
                      color: item.isOverdue
                          ? AppColors.danger
                          : AppColors.textSecondary)),
            ]),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.notes,
                    style: AppText.body(13, color: AppColors.textSecondary)),
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => store.toggleScheduleItem(item.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? Colors.white.withOpacity(0.06)
                      : item.type.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        item.isCompleted
                            ? Icons.undo_rounded
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: item.isCompleted
                            ? AppColors.textSecondary
                            : Colors.black),
                    const SizedBox(width: 6),
                    Text(item.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
                        style: AppText.body(13,
                            weight: FontWeight.w600,
                            color: item.isCompleted
                                ? AppColors.textSecondary
                                : Colors.black)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _studyGuideSection(
          ScheduleItem item, StudyGuide? guide, GoalStore store) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Study Guide',
                style: AppText.display(15, weight: FontWeight.w700)),
            const Spacer(),
            if (guide != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Generated',
                    style: AppText.body(11,
                        weight: FontWeight.w600, color: AppColors.success)),
              ),
          ]),
          const SizedBox(height: 10),
          if (guide != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.type.color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: item.type.color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide.overview,
                      style: AppText.body(12, color: AppColors.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => StudyGuideDialog(
                              guide: guide, accentColor: item.type.color),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: item.type.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.menu_book_rounded,
                                  size: 13, color: Colors.black),
                              const SizedBox(width: 6),
                              Text('Open Study Guide',
                                  style: AppText.body(13,
                                      weight: FontWeight.w600,
                                      color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _generatingGuide
                          ? null
                          : () => _generateGuide(item, store),
                      child: Text('Regenerate',
                          style:
                              AppText.body(12, color: AppColors.textSecondary)),
                    ),
                  ]),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  _generatingGuide ? null : () => _generateGuide(item, store),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    item.type.color,
                    item.type.color.withOpacity(0.7)
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_generatingGuide) ...[
                      const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Colors.black)),
                      const SizedBox(width: 8),
                      Text('Claude is researching…',
                          style: AppText.body(13,
                              weight: FontWeight.w600, color: Colors.black)),
                    ] else ...[
                      const Icon(Icons.auto_awesome_rounded,
                          size: 13, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('Generate Study Guide with Claude',
                          style: AppText.body(13,
                              weight: FontWeight.w600, color: Colors.black)),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (_guideError != null)
            Text(_guideError!,
                style: AppText.body(12, color: AppColors.danger)),
        ],
      );

  Widget _upcomingSection(List<ScheduleItem> upcoming, GoalStore store) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Upcoming in ${widget.item.subject}',
                style: AppText.display(15, weight: FontWeight.w700)),
            const Spacer(),
            Text('${upcoming.length} item${upcoming.length == 1 ? "" : "s"}',
                style: AppText.body(11, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 10),
          ...upcoming.map((u) => _upcomingRow(u, store)),
        ],
      );

  Widget _upcomingRow(ScheduleItem u, GoalStore store) {
    final expanded = _expandedUpcoming.contains(u.id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        if (expanded)
          _expandedUpcoming.remove(u.id);
        else
          _expandedUpcoming.add(u.id);
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: u.type.color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.title,
                        style: AppText.body(13, weight: FontWeight.w500)),
                    Text('Due in ${u.daysUntilDue}d',
                        style:
                            AppText.body(11, color: AppColors.textSecondary)),
                  ],
                )),
                Row(children: [
                  Text(u.type.label,
                      style: AppText.body(10,
                          color: u.type.color.withOpacity(0.7))),
                  const SizedBox(width: 6),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      size: 14, color: AppColors.textTertiary),
                ]),
              ]),
            ),
            if (expanded) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (u.notes.isNotEmpty)
                      Text(u.notes,
                          style:
                              AppText.body(12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => store.toggleScheduleItem(u.id),
                      child: Text('Mark Complete',
                          style: AppText.body(11,
                              weight: FontWeight.w600, color: u.type.color)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dueDateString(ScheduleItem item) {
    final days = item.daysUntilDue;
    final date =
        '${item.dueDate.month}/${item.dueDate.day}/${item.dueDate.year}';
    if (item.isCompleted) return 'Completed · $date';
    if (days < 0)
      return 'Overdue by ${-days} day${-days == 1 ? "" : "s"} · $date';
    if (days == 0) return 'Due today · $date';
    if (days == 1) return 'Due tomorrow · $date';
    return 'Due in $days days · $date';
  }

  Future<void> _generateGuide(ScheduleItem item, GoalStore store) async {
    setState(() {
      _generatingGuide = true;
      _guideError = null;
    });
    try {
      final guide = await AnthropicService.generateStudyGuide(
        topic: item.title,
        subject: item.subject,
        itemType: item.type,
        dueDate: item.dueDate,
        notes: item.notes,
      );
      store.saveStudyGuide(guide, item.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) =>
              StudyGuideDialog(guide: guide, accentColor: item.type.color),
        );
      }
    } catch (e) {
      setState(() => _guideError = e.toString());
    }
    setState(() => _generatingGuide = false);
  }
}
