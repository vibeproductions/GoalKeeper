// lib/models/models.dart
// All GoalKeeper data models — translated from Swift to Dart

import 'package:flutter/material.dart';
import 'package:goalkeeper/theme/app_theme.dart';

// ─── Goal Step ────────────────────────────────────────────────────────────────

class GoalStep {
  final String id;
  String title;
  String detail;
  String estimatedTime;
  bool isCompleted;
  List<String> tips;

  GoalStep({
    String? id,
    required this.title,
    required this.detail,
    required this.estimatedTime,
    this.isCompleted = false,
    List<String>? tips,
  })  : id = id ?? _uuid(),
        tips = tips ?? [];

  GoalStep copyWith({
    String? title,
    String? detail,
    String? estimatedTime,
    bool? isCompleted,
    List<String>? tips,
  }) =>
      GoalStep(
        id: id,
        title: title ?? this.title,
        detail: detail ?? this.detail,
        estimatedTime: estimatedTime ?? this.estimatedTime,
        isCompleted: isCompleted ?? this.isCompleted,
        tips: tips ?? this.tips,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'estimatedTime': estimatedTime,
        'isCompleted': isCompleted,
        'tips': tips,
      };

  factory GoalStep.fromJson(Map<String, dynamic> j) => GoalStep(
        id: j['id'] as String?,
        title: j['title'] as String,
        detail: j['detail'] as String,
        estimatedTime: j['estimatedTime'] as String,
        isCompleted: j['isCompleted'] as bool? ?? false,
        tips: (j['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

// ─── Goal Type ────────────────────────────────────────────────────────────────

enum GoalType {
  assignment('Assignment', Icons.description_rounded, AppColors.assignment),
  project('Project', Icons.folder_rounded, AppColors.project),
  personalGoal('Personal Goal', Icons.star_rounded, AppColors.personalGoal),
  habit('Habit', Icons.repeat_rounded, AppColors.habit),
  examPrep('Exam Prep', Icons.school_rounded, AppColors.examPrep),
  creative('Creative', Icons.brush_rounded, AppColors.creative);

  const GoalType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static GoalType fromString(String s) =>
      GoalType.values.firstWhere((e) => e.label == s, orElse: () => GoalType.assignment);
}

// ─── Goal Priority ────────────────────────────────────────────────────────────

enum GoalPriority {
  low('Low', AppColors.success),
  medium('Medium', AppColors.warning),
  high('High', AppColors.danger);

  const GoalPriority(this.label, this.color);
  final String label;
  final Color color;

  static GoalPriority fromString(String s) =>
      GoalPriority.values.firstWhere((e) => e.label == s, orElse: () => GoalPriority.medium);
}

// ─── Goal ─────────────────────────────────────────────────────────────────────

class Goal {
  final String id;
  String title;
  String description;
  GoalType type;
  GoalPriority priority;
  List<GoalStep> steps;
  DateTime createdDate;
  DateTime? dueDate;
  String rubricText;
  bool isAnalyzed;
  String aiSummary;
  int currentStepIndex;

  Goal({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.priority = GoalPriority.medium,
    List<GoalStep>? steps,
    DateTime? createdDate,
    this.dueDate,
    this.rubricText = '',
    this.isAnalyzed = false,
    this.aiSummary = '',
    this.currentStepIndex = 0,
  })  : id = id ?? _uuid(),
        steps = steps ?? [],
        createdDate = createdDate ?? DateTime.now();

  double get progress {
    if (steps.isEmpty) return 0;
    return steps.where((s) => s.isCompleted).length / steps.length;
  }

  int get progressPercent => (progress * 100).toInt();

  GoalStep? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  bool get isComplete => progress >= 1.0;

  int? get daysUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now()).inDays;
  }

  bool get isOverdue {
    final days = daysUntilDue;
    return days != null && days < 0 && !isComplete;
  }

  Goal copyWith({
    String? title,
    String? description,
    GoalType? type,
    GoalPriority? priority,
    List<GoalStep>? steps,
    DateTime? dueDate,
    String? rubricText,
    bool? isAnalyzed,
    String? aiSummary,
    int? currentStepIndex,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        steps: steps ?? this.steps,
        createdDate: createdDate,
        dueDate: dueDate ?? this.dueDate,
        rubricText: rubricText ?? this.rubricText,
        isAnalyzed: isAnalyzed ?? this.isAnalyzed,
        aiSummary: aiSummary ?? this.aiSummary,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.label,
        'priority': priority.label,
        'steps': steps.map((s) => s.toJson()).toList(),
        'createdDate': createdDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'rubricText': rubricText,
        'isAnalyzed': isAnalyzed,
        'aiSummary': aiSummary,
        'currentStepIndex': currentStepIndex,
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String?,
        title: j['title'] as String,
        description: j['description'] as String,
        type: GoalType.fromString(j['type'] as String),
        priority: GoalPriority.fromString(j['priority'] as String? ?? 'Medium'),
        steps: (j['steps'] as List<dynamic>?)
                ?.map((s) => GoalStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        createdDate: DateTime.parse(j['createdDate'] as String),
        dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate'] as String) : null,
        rubricText: j['rubricText'] as String? ?? '',
        isAnalyzed: j['isAnalyzed'] as bool? ?? false,
        aiSummary: j['aiSummary'] as String? ?? '',
        currentStepIndex: j['currentStepIndex'] as int? ?? 0,
      );
}

// ─── Schedule Item Type ───────────────────────────────────────────────────────

enum ScheduleItemType {
  homework('Homework', Icons.edit_note_rounded, AppColors.homework),
  test('Test', Icons.find_in_page_rounded, AppColors.test),
  quiz('Quiz', Icons.quiz_rounded, AppColors.quiz),
  project('Project', Icons.folder_rounded, AppColors.examPrep),
  reading('Reading', Icons.menu_book_rounded, AppColors.reading),
  other('Other', Icons.event_available_rounded, AppColors.textSecondary);

  const ScheduleItemType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static ScheduleItemType fromString(String s) =>
      ScheduleItemType.values.firstWhere((e) => e.label.toLowerCase() == s.toLowerCase(),
          orElse: () => ScheduleItemType.other);
}

// ─── Schedule Item ────────────────────────────────────────────────────────────

class ScheduleItem {
  final String id;
  String title;
  String subject;
  ScheduleItemType type;
  DateTime dueDate;
  String notes;
  bool isCompleted;
  DateTime createdDate;

  ScheduleItem({
    String? id,
    required this.title,
    required this.subject,
    required this.type,
    required this.dueDate,
    this.notes = '',
    this.isCompleted = false,
    DateTime? createdDate,
  })  : id = id ?? _uuid(),
        createdDate = createdDate ?? DateTime.now();

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => daysUntilDue < 0 && !isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'type': type.label,
        'dueDate': dueDate.toIso8601String(),
        'notes': notes,
        'isCompleted': isCompleted,
        'createdDate': createdDate.toIso8601String(),
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
        id: j['id'] as String?,
        title: j['title'] as String,
        subject: j['subject'] as String,
        type: ScheduleItemType.fromString(j['type'] as String),
        dueDate: DateTime.parse(j['dueDate'] as String),
        notes: j['notes'] as String? ?? '',
        isCompleted: j['isCompleted'] as bool? ?? false,
        createdDate: j['createdDate'] != null
            ? DateTime.parse(j['createdDate'] as String)
            : DateTime.now(),
      );
}

// ─── Calendar Event ───────────────────────────────────────────────────────────

enum CalendarEventColor {
  blue('Blue', AppColors.eventBlue),
  red('Red', AppColors.eventRed),
  green('Green', AppColors.eventGreen),
  orange('Orange', AppColors.eventOrange),
  purple('Purple', AppColors.eventPurple),
  teal('Teal', AppColors.eventTeal);

  const CalendarEventColor(this.label, this.color);
  final String label;
  final Color color;

  static CalendarEventColor fromString(String s) =>
      CalendarEventColor.values.firstWhere((e) => e.label == s,
          orElse: () => CalendarEventColor.blue);
}

enum CalendarEventSource { manual, ics }

class CalendarEvent {
  final String id;
  String title;
  String notes;
  DateTime startDate;
  DateTime? endDate;
  bool isAllDay;
  CalendarEventColor color;
  CalendarEventSource source;
  String calendarName;

  CalendarEvent({
    String? id,
    required this.title,
    this.notes = '',
    required this.startDate,
    this.endDate,
    this.isAllDay = true,
    this.color = CalendarEventColor.blue,
    this.source = CalendarEventSource.manual,
    this.calendarName = '',
  }) : id = id ?? _uuid();

  int get daysUntil {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return start.difference(today).inDays;
  }

  bool get isPast => daysUntil < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isAllDay': isAllDay,
        'color': color.label,
        'source': source.name,
        'calendarName': calendarName,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> j) => CalendarEvent(
        id: j['id'] as String?,
        title: j['title'] as String,
        notes: j['notes'] as String? ?? '',
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: j['endDate'] != null ? DateTime.parse(j['endDate'] as String) : null,
        isAllDay: j['isAllDay'] as bool? ?? true,
        color: CalendarEventColor.fromString(j['color'] as String? ?? 'Blue'),
        source: j['source'] == 'ics' ? CalendarEventSource.ics : CalendarEventSource.manual,
        calendarName: j['calendarName'] as String? ?? '',
      );
}

// ─── Study Guide ──────────────────────────────────────────────────────────────

class StudyGuideSection {
  final String id;
  String heading;
  String content;
  List<String> keyPoints;

  StudyGuideSection({
    String? id,
    required this.heading,
    required this.content,
    List<String>? keyPoints,
  })  : id = id ?? _uuid(),
        keyPoints = keyPoints ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'heading': heading,
        'content': content,
        'keyPoints': keyPoints,
      };

  factory StudyGuideSection.fromJson(Map<String, dynamic> j) => StudyGuideSection(
        id: j['id'] as String?,
        heading: j['heading'] as String,
        content: j['content'] as String,
        keyPoints: (j['keyPoints'] as List<dynamic>?)?.cast<String>() ?? [],
      );
}

class PracticeQuestion {
  final String id;
  String question;
  String answer;

  PracticeQuestion({String? id, required this.question, required this.answer})
      : id = id ?? _uuid();

  Map<String, dynamic> toJson() => {'id': id, 'question': question, 'answer': answer};

  factory PracticeQuestion.fromJson(Map<String, dynamic> j) =>
      PracticeQuestion(id: j['id'] as String?, question: j['question'] as String, answer: j['answer'] as String);
}

class StudyGuide {
  final String id;
  String title;
  String overview;
  List<StudyGuideSection> sections;
  List<PracticeQuestion> practiceQuestions;
  List<String> studyTips;
  DateTime generatedDate;

  StudyGuide({
    String? id,
    required this.title,
    required this.overview,
    required this.sections,
    required this.practiceQuestions,
    required this.studyTips,
    DateTime? generatedDate,
  })  : id = id ?? _uuid(),
        generatedDate = generatedDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'overview': overview,
        'sections': sections.map((s) => s.toJson()).toList(),
        'practiceQuestions': practiceQuestions.map((q) => q.toJson()).toList(),
        'studyTips': studyTips,
        'generatedDate': generatedDate.toIso8601String(),
      };

  factory StudyGuide.fromJson(Map<String, dynamic> j) => StudyGuide(
        id: j['id'] as String?,
        title: j['title'] as String,
        overview: j['overview'] as String,
        sections: (j['sections'] as List<dynamic>)
            .map((s) => StudyGuideSection.fromJson(s as Map<String, dynamic>))
            .toList(),
        practiceQuestions: (j['practiceQuestions'] as List<dynamic>)
            .map((q) => PracticeQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        studyTips: (j['studyTips'] as List<dynamic>).cast<String>(),
        generatedDate: j['generatedDate'] != null
            ? DateTime.parse(j['generatedDate'] as String)
            : DateTime.now(),
      );
}

// ─── Unified deadline (for Upcoming calendar tab) ─────────────────────────────

enum DeadlineKind { goal, scheduleItem, event }

class AnyDeadline {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;
  final IconData icon;
  final DeadlineKind kind;

  AnyDeadline({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    required this.icon,
    required this.kind,
  });

  int get daysUntil {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final d     = DateTime(date.year, date.month, date.day);
    return d.difference(today).inDays;
  }
}

// ─── UUID helper (no package needed) ─────────────────────────────────────────

int _uuidCounter = 0;
String _uuid() {
  // Simple unique ID — use the `uuid` package for production if preferred
  final now = DateTime.now().microsecondsSinceEpoch;
  return '${now}_${_uuidCounter++}';
}
