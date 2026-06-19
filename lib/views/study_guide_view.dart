// lib/views/study_guide_view.dart

import 'package:flutter/material.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/theme/app_theme.dart';

class StudyGuideDialog extends StatefulWidget {
  final StudyGuide guide;
  final Color accentColor;
  const StudyGuideDialog(
      {super.key, required this.guide, required this.accentColor});
  @override
  State<StudyGuideDialog> createState() => _StudyGuideDialogState();
}

class _StudyGuideDialogState extends State<StudyGuideDialog> {
  int _tab = 0;
  final Set<String> _expandedSections = {};
  final Set<String> _revealedAnswers = {};

  @override
  void initState() {
    super.initState();
    if (widget.guide.sections.isNotEmpty) {
      _expandedSections.add(widget.guide.sections.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SizedBox(
        width: 600,
        height: 700,
        child: Column(
          children: [
            _header,
            _tabBar,
            Expanded(
                child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_tab == 0) ..._contentTab,
                if (_tab == 1) ..._practiceTab,
                if (_tab == 2) ..._tipsTab,
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget get _header => Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        decoration: BoxDecoration(
          color: widget.accentColor.withOpacity(0.07),
          border: Border(
              bottom: BorderSide(color: widget.accentColor.withOpacity(0.2))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.menu_book_rounded,
                  size: 13, color: widget.accentColor),
              const SizedBox(width: 6),
              Text('STUDY GUIDE',
                  style: AppText.label(10, color: widget.accentColor)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppColors.textTertiary),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            Text(widget.guide.title,
                style: AppText.display(18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.guide.overview,
                style: AppText.body(12, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget get _tabBar => Row(
        children: [
          _tabItem('Study Guide', 0),
          _tabItem('Practice', 1),
          _tabItem('Tips', 2),
        ],
      );

  Widget _tabItem(String label, int idx) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _tab = idx),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(label,
                    style: AppText.body(12,
                        weight: _tab == idx ? FontWeight.w600 : FontWeight.w400,
                        color: _tab == idx
                            ? widget.accentColor
                            : AppColors.textSecondary)),
              ),
              Container(
                  height: 2,
                  color: _tab == idx ? widget.accentColor : Colors.transparent),
            ],
          ),
        ),
      );

  List<Widget> get _contentTab => widget.guide.sections.map((section) {
        final expanded = _expandedSections.contains(section.id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (expanded)
              _expandedSections.remove(section.id);
            else
              _expandedSections.add(section.id);
          }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: expanded
                      ? widget.accentColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Icon(expanded ? Icons.expand_more : Icons.chevron_right,
                        size: 14, color: widget.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(section.heading,
                            style: AppText.body(14, weight: FontWeight.w600))),
                    Text('${section.keyPoints.length} key points',
                        style: AppText.body(10, color: AppColors.textTertiary)),
                  ]),
                ),
                if (expanded) ...[
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.content,
                            style: AppText.body(12,
                                color: AppColors.textSecondary)),
                        if (section.keyPoints.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('KEY POINTS', style: AppText.label(9)),
                          const SizedBox(height: 6),
                          ...section.keyPoints.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.only(top: 5),
                                      decoration: BoxDecoration(
                                          color: widget.accentColor,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(p,
                                            style: AppText.body(12,
                                                color: Colors.white
                                                    .withOpacity(0.85)))),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList();

  List<Widget> get _practiceTab => [
        Row(children: [
          Expanded(
              child: Text('Tap to reveal answers',
                  style: AppText.body(12, color: AppColors.textTertiary))),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              if (_revealedAnswers.length ==
                  widget.guide.practiceQuestions.length) {
                _revealedAnswers.clear();
              } else {
                _revealedAnswers
                    .addAll(widget.guide.practiceQuestions.map((q) => q.id));
              }
            }),
            child: Text(
              _revealedAnswers.length == widget.guide.practiceQuestions.length
                  ? 'Hide All'
                  : 'Reveal All',
              style: AppText.body(11,
                  weight: FontWeight.w600, color: widget.accentColor),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ...widget.guide.practiceQuestions.asMap().entries.map((e) {
          final q = e.value;
          final revealed = _revealedAnswers.contains(q.id);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() {
              if (revealed)
                _revealedAnswers.remove(q.id);
              else
                _revealedAnswers.add(q.id);
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: revealed
                    ? AppColors.success.withOpacity(0.06)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: revealed
                        ? AppColors.success.withOpacity(0.2)
                        : Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text('${e.key + 1}',
                              style: AppText.body(10,
                                  weight: FontWeight.w700,
                                  color: widget.accentColor))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(q.question,
                            style: AppText.body(13, weight: FontWeight.w500))),
                    Icon(
                        revealed
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 14,
                        color: AppColors.textTertiary),
                  ]),
                  if (revealed) ...[
                    const Divider(height: 16, color: AppColors.divider),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 13, color: AppColors.success),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(q.answer,
                                  style: AppText.body(12,
                                      color: const Color(0xFFA8E6CF)))),
                        ]),
                  ],
                ],
              ),
            ),
          );
        }),
      ];

  List<Widget> get _tipsTab => widget.guide.studyTips
      .map((tip) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: AppColors.personalGoal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.lightbulb_rounded,
                    size: 15, color: AppColors.personalGoal),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(tip,
                      style: AppText.body(13,
                          color: Colors.white.withOpacity(0.85)))),
            ]),
          ))
      .toList();
}
