// lib/store/goal_store.dart
// State management — equivalent to GoalStore.swift using Provider

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goalkeeper_flutter/models/models.dart';
import 'package:flutter/material.dart';

// Detail panel selection — equivalent to DetailSelection enum in Swift
enum DetailSelection { goal, scheduleItem, calendarEvent, none }

class GoalStore extends ChangeNotifier {
  // ── Data ──────────────────────────────────────────────────────────────────
  List<Goal>          goals          = [];
  List<ScheduleItem>  scheduleItems  = [];
  List<CalendarEvent> calendarEvents = [];
  Map<String, StudyGuide> studyGuides = {}; // keyed by ScheduleItem.id

  // ── Selection state ───────────────────────────────────────────────────────
  String?          selectedGoalID          ;
  String?          selectedScheduleItemID  ;
  String?          selectedCalendarEventID ;
  DetailSelection  detailSelection = DetailSelection.none;
  DateTime         selectedDate    = DateTime.now();

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const _goalsKey       = 'gk_goals_v1';
  static const _scheduleKey    = 'gk_schedule_v1';
  static const _eventsKey      = 'gk_events_v1';
  static const _studyGuideKey  = 'gk_studyguides_v1';

  GoalStore() {
    _load();
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  Goal?          get selectedGoal          => goals.where((g) => g.id == selectedGoalID).firstOrNull;
  ScheduleItem?  get selectedScheduleItem  => scheduleItems.where((i) => i.id == selectedScheduleItemID).firstOrNull;
  CalendarEvent? get selectedCalendarEvent => calendarEvents.where((e) => e.id == selectedCalendarEventID).firstOrNull;

  List<Goal> get activeGoals    => goals.where((g) => !g.isComplete).toList();
  List<Goal> get completedGoals => goals.where((g) => g.isComplete).toList();
  List<Goal> get overdueGoals   => goals.where((g) => g.isOverdue).toList();

  List<CalendarEvent> get upcomingEvents =>
      calendarEvents.where((e) => !e.isPast).toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

  List<String> get subjects =>
      scheduleItems.map((i) => i.subject).toSet().toList()..sort();

  List<ScheduleItem> itemsForSubject(String subject) =>
      scheduleItems.where((i) => i.subject == subject).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<ScheduleItem> upcomingItemsForSubject(String subject, String excludeID) =>
      scheduleItems
          .where((i) => i.subject == subject && i.id != excludeID && !i.isCompleted)
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  StudyGuide? studyGuideFor(String itemID) => studyGuides[itemID];

  // All upcoming deadlines — goals + schedule items + events sorted by date
  List<AnyDeadline> get allUpcomingDeadlines {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final items = <AnyDeadline>[];

    for (final goal in activeGoals) {
      if (goal.dueDate != null && !goal.dueDate!.isBefore(today)) {
        items.add(AnyDeadline(
          id: goal.id, title: goal.title, subtitle: goal.type.label,
          date: goal.dueDate!, color: goal.type.color,
          icon: goal.type.icon, kind: DeadlineKind.goal,
        ));
      }
    }
    for (final item in scheduleItems.where((i) => !i.isCompleted)) {
      if (!item.dueDate.isBefore(today)) {
        items.add(AnyDeadline(
          id: item.id, title: item.title, subtitle: item.subject,
          date: item.dueDate, color: item.type.color,
          icon: item.type.icon, kind: DeadlineKind.scheduleItem,
        ));
      }
    }
    for (final event in upcomingEvents) {
      items.add(AnyDeadline(
        id: event.id, title: event.title,
        subtitle: event.calendarName.isEmpty ? 'Event' : event.calendarName,
        date: event.startDate, color: event.color.color,
        icon: Icons.calendar_today_rounded, kind: DeadlineKind.event,
      ));
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  // ── Goal CRUD ─────────────────────────────────────────────────────────────
  void addGoal(Goal goal) {
    goals.add(goal);
    selectedGoalID = goal.id;
    detailSelection = DetailSelection.goal;
    _save(); notifyListeners();
  }

  void updateGoal(Goal goal) {
    final idx = goals.indexWhere((g) => g.id == goal.id);
    if (idx != -1) { goals[idx] = goal; _save(); notifyListeners(); }
  }

  void deleteGoal(String id) {
    goals.removeWhere((g) => g.id == id);
    if (selectedGoalID == id) {
      selectedGoalID = goals.isNotEmpty ? goals.first.id : null;
      detailSelection = goals.isNotEmpty ? DetailSelection.goal : DetailSelection.none;
    }
    _save(); notifyListeners();
  }

  void toggleStep(String goalID, String stepID) {
    final gIdx = goals.indexWhere((g) => g.id == goalID);
    if (gIdx == -1) return;
    final sIdx = goals[gIdx].steps.indexWhere((s) => s.id == stepID);
    if (sIdx == -1) return;
    goals[gIdx].steps[sIdx].isCompleted = !goals[gIdx].steps[sIdx].isCompleted;
    final nextIdx = goals[gIdx].steps.indexWhere((s) => !s.isCompleted);
    goals[gIdx].currentStepIndex = nextIdx == -1 ? goals[gIdx].steps.length : nextIdx;
    _save(); notifyListeners();
  }

  void selectGoal(String id) {
    selectedGoalID = id;
    detailSelection = DetailSelection.goal;
    notifyListeners();
  }

  // ── Schedule CRUD ─────────────────────────────────────────────────────────
  void addScheduleItem(ScheduleItem item) {
    scheduleItems.add(item);
    selectedScheduleItemID = item.id;
    detailSelection = DetailSelection.scheduleItem;
    _save(); notifyListeners();
  }

  void addScheduleItems(List<ScheduleItem> items) {
    scheduleItems.addAll(items);
    if (items.isNotEmpty) {
      selectedScheduleItemID = items.first.id;
      detailSelection = DetailSelection.scheduleItem;
    }
    _save(); notifyListeners();
  }

  void updateScheduleItem(ScheduleItem item) {
    final idx = scheduleItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) { scheduleItems[idx] = item; _save(); notifyListeners(); }
  }

  void deleteScheduleItem(String id) {
    scheduleItems.removeWhere((i) => i.id == id);
    if (selectedScheduleItemID == id) {
      selectedScheduleItemID = null;
      detailSelection = DetailSelection.none;
    }
    _save(); notifyListeners();
  }

  void toggleScheduleItem(String id) {
    final idx = scheduleItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      scheduleItems[idx].isCompleted = !scheduleItems[idx].isCompleted;
      _save(); notifyListeners();
    }
  }

  void selectScheduleItem(String id) {
    selectedScheduleItemID = id;
    detailSelection = DetailSelection.scheduleItem;
    notifyListeners();
  }

  // ── Calendar Events CRUD ──────────────────────────────────────────────────
  void addEvent(CalendarEvent event) {
    calendarEvents.add(event);
    selectedCalendarEventID = event.id;
    detailSelection = DetailSelection.calendarEvent;
    _save(); notifyListeners();
  }

  void addEvents(List<CalendarEvent> events) {
    calendarEvents.addAll(events);
    _save(); notifyListeners();
  }

  void deleteEvent(String id) {
    calendarEvents.removeWhere((e) => e.id == id);
    if (selectedCalendarEventID == id) {
      selectedCalendarEventID = null;
      detailSelection = DetailSelection.none;
    }
    _save(); notifyListeners();
  }

  void selectEvent(String id) {
    selectedCalendarEventID = id;
    detailSelection = DetailSelection.calendarEvent;
    notifyListeners();
  }

  // ── Study Guide ───────────────────────────────────────────────────────────
  void saveStudyGuide(StudyGuide guide, String itemID) {
    studyGuides[itemID] = guide;
    _save(); notifyListeners();
  }

  // ── Calendar helpers ──────────────────────────────────────────────────────
  Map<DateTime, List<Goal>> goalsForMonth(DateTime month) {
    final result = <DateTime, List<Goal>>{};
    for (final goal in goals) {
      final ref = goal.dueDate ?? goal.createdDate;
      if (ref.year == month.year && ref.month == month.month) {
        final day = DateTime(ref.year, ref.month, ref.day);
        result.putIfAbsent(day, () => []).add(goal);
      }
    }
    return result;
  }

  Map<DateTime, List<ScheduleItem>> scheduleForMonth(DateTime month) {
    final result = <DateTime, List<ScheduleItem>>{};
    for (final item in scheduleItems) {
      if (item.dueDate.year == month.year && item.dueDate.month == month.month) {
        final day = DateTime(item.dueDate.year, item.dueDate.month, item.dueDate.day);
        result.putIfAbsent(day, () => []).add(item);
      }
    }
    return result;
  }

  Map<DateTime, List<CalendarEvent>> eventsForMonth(DateTime month) {
    final result = <DateTime, List<CalendarEvent>>{};
    for (final event in calendarEvents) {
      if (event.startDate.year == month.year && event.startDate.month == month.month) {
        final day = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        result.putIfAbsent(day, () => []).add(event);
      }
    }
    return result;
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_goalsKey,      jsonEncode(goals.map((g) => g.toJson()).toList()));
    prefs.setString(_scheduleKey,   jsonEncode(scheduleItems.map((i) => i.toJson()).toList()));
    prefs.setString(_eventsKey,     jsonEncode(calendarEvents.map((e) => e.toJson()).toList()));
    prefs.setString(_studyGuideKey, jsonEncode(studyGuides.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final goalsJson = prefs.getString(_goalsKey);
    if (goalsJson != null) {
      goals = (jsonDecode(goalsJson) as List)
          .map((j) => Goal.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final scheduleJson = prefs.getString(_scheduleKey);
    if (scheduleJson != null) {
      scheduleItems = (jsonDecode(scheduleJson) as List)
          .map((j) => ScheduleItem.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final eventsJson = prefs.getString(_eventsKey);
    if (eventsJson != null) {
      calendarEvents = (jsonDecode(eventsJson) as List)
          .map((j) => CalendarEvent.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    final guidesJson = prefs.getString(_studyGuideKey);
    if (guidesJson != null) {
      final map = jsonDecode(guidesJson) as Map<String, dynamic>;
      studyGuides = map.map((k, v) => MapEntry(k, StudyGuide.fromJson(v as Map<String, dynamic>)));
    }

    if (goals.isEmpty) _insertSampleData();
    notifyListeners();
  }

  void _insertSampleData() {
    final now = DateTime.now();

    final g1 = Goal(
      title: 'Research Paper on Climate Change',
      description: 'Write a 10-page research paper covering recent climate data and solutions',
      type: GoalType.assignment,
      priority: GoalPriority.high,
      dueDate: now.add(const Duration(days: 5)),
      isAnalyzed: true,
      aiSummary: 'A structured paper requiring literature review, data analysis, and clear argumentation.',
      steps: [
        GoalStep(title: 'Define research scope', detail: 'Narrow your topic to 2–3 specific climate issues', estimatedTime: '30 min', isCompleted: true),
        GoalStep(title: 'Gather sources', detail: 'Find 8–10 credible academic sources', estimatedTime: '2 hrs', isCompleted: true),
        GoalStep(title: 'Create outline', detail: 'Draft a detailed outline for all sections', estimatedTime: '45 min'),
        GoalStep(title: 'Write first draft', detail: 'Write the full paper without stopping to edit', estimatedTime: '4 hrs'),
        GoalStep(title: 'Revise & cite', detail: 'Add citations, fix grammar, and polish the argument', estimatedTime: '2 hrs'),
      ],
      currentStepIndex: 2,
    );

    final g2 = Goal(
      title: 'Learn Flutter in 30 Days',
      description: 'Master Flutter by building real apps',
      type: GoalType.project,
      priority: GoalPriority.medium,
      dueDate: now.add(const Duration(days: 22)),
      isAnalyzed: true,
      aiSummary: 'A self-paced learning project broken into progressive weekly milestones.',
      steps: [
        GoalStep(title: 'Flutter basics', detail: 'Widgets, state, layout', estimatedTime: '3 days', isCompleted: true),
        GoalStep(title: 'Navigation & state', detail: 'Provider, GoRouter', estimatedTime: '4 days'),
        GoalStep(title: 'Animations', detail: 'AnimatedWidget, CustomPainter', estimatedTime: '3 days'),
        GoalStep(title: 'Networking', detail: 'http package, async/await', estimatedTime: '4 days'),
        GoalStep(title: 'Final app', detail: 'Build and publish a polished app', estimatedTime: '1 week'),
      ],
      currentStepIndex: 1,
    );

    goals = [g1, g2];
    selectedGoalID = g1.id;
    detailSelection = DetailSelection.goal;

    scheduleItems = [
      ScheduleItem(title: 'Chapter 5 Problems', subject: 'Math', type: ScheduleItemType.homework, dueDate: now.add(const Duration(days: 1))),
      ScheduleItem(title: 'Midterm Exam', subject: 'Math', type: ScheduleItemType.test, dueDate: now.add(const Duration(days: 8))),
      ScheduleItem(title: 'Read Chapter 3', subject: 'History', type: ScheduleItemType.reading, dueDate: now.add(const Duration(days: 2))),
      ScheduleItem(title: 'Quiz on WWII', subject: 'History', type: ScheduleItemType.quiz, dueDate: now.add(const Duration(days: 4))),
      ScheduleItem(title: 'Lab Report', subject: 'Biology', type: ScheduleItemType.homework, dueDate: now.add(const Duration(days: 3))),
    ];

    calendarEvents = [
      CalendarEvent(title: 'Spring Break', startDate: now.add(const Duration(days: 14)), endDate: now.add(const Duration(days: 21)), color: CalendarEventColor.green),
      CalendarEvent(title: 'Final Exams Begin', startDate: now.add(const Duration(days: 30)), color: CalendarEventColor.red),
    ];

    _save();
  }
}
