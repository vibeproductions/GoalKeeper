// lib/views/main_scaffold.dart
// 3-column layout — equivalent to ContentView.swift NavigationSplitView

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/theme/app_theme.dart';
import 'package:goalkeeper/views/sidebar_view.dart';
import 'package:goalkeeper/views/calendar_dashboard_view.dart';
import 'package:goalkeeper/views/goal_detail_view.dart';
import 'package:goalkeeper/views/schedule_detail_view.dart';
import 'package:goalkeeper/views/calendar_event_detail_view.dart';
import 'package:goalkeeper/views/add_goal_view.dart';
import 'package:goalkeeper/views/import_schedule_view.dart';
import 'package:goalkeeper/views/import_calendar_view.dart';
import 'package:goalkeeper/views/settings_view.dart';

// Intent for ⌘, shortcut
class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

// Intent for ⌘N shortcut
class _NewGoalIntent extends Intent {
  const _NewGoalIntent();
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  double _sidebarWidth  = 250;
  double _calendarWidth = 370;
  static const double _minSidebarWidth  = 200;
  static const double _maxSidebarWidth  = 300;
  static const double _minCalendarWidth = 300;
  static const double _maxCalendarWidth = 440;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.comma):
            const _OpenSettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const _NewGoalIntent(),
      },
      child: Actions(
        actions: {
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) { _showSettings(); return null; },
          ),
          _NewGoalIntent: CallbackAction<_NewGoalIntent>(
            onInvoke: (_) { _showAddGoal(); return null; },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _TitleBar(
                  onNewGoal: _showAddGoal,
                  onSettings: _showSettings,
                ),
                Expanded(
                  child: Row(
                    children: [
                      // ── Sidebar ──────────────────────────────────────────
                      SizedBox(
                        width: _sidebarWidth,
                        child: SidebarView(
                          onAddGoal:        _showAddGoal,
                          onImportSchedule: _showImportSchedule,
                          onImportCalendar: _showImportCalendar,
                        ),
                      ),

                      _ResizeHandle(
                        onDrag: (dx) => setState(() {
                          _sidebarWidth = (_sidebarWidth + dx)
                              .clamp(_minSidebarWidth, _maxSidebarWidth);
                        }),
                      ),

                      // ── Calendar/Dashboard ────────────────────────────────
                      SizedBox(
                        width: _calendarWidth,
                        child: const CalendarDashboardView(),
                      ),

                      _ResizeHandle(
                        onDrag: (dx) => setState(() {
                          _calendarWidth = (_calendarWidth + dx)
                              .clamp(_minCalendarWidth, _maxCalendarWidth);
                        }),
                      ),

                      // ── Detail panel ──────────────────────────────────────
                      const Expanded(child: _DetailPanel()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddGoal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GoalStore>(),
        child: const AddGoalView(),
      ),
    );
  }

  void _showImportSchedule() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GoalStore>(),
        child: const ImportScheduleView(),
      ),
    );
  }

  void _showImportCalendar() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GoalStore>(),
        child: const ImportCalendarView(),
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GoalStore>(),
        child: const SettingsView(),
      ),
    );
  }
}

// ── Detail Panel router ───────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GoalStore>();

    switch (store.detailSelection) {
      case DetailSelection.goal:
        final goal = store.selectedGoal;
        if (goal != null) return GoalDetailView(goal: goal);
        return const _EmptyDetail();

      case DetailSelection.scheduleItem:
        final item = store.selectedScheduleItem;
        if (item != null) return ScheduleDetailView(item: item);
        return const _EmptyDetail();

      case DetailSelection.calendarEvent:
        final event = store.selectedCalendarEvent;
        if (event != null) return CalendarEventDetailView(event: event);
        return const _EmptyDetail();

      case DetailSelection.none:
        return const _EmptyDetail();
    }
  }
}

// ── Empty detail placeholder ──────────────────────────────────────────────────

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                size: 44, color: AppColors.accent.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Select a goal',
                style: AppText.display(18,
                    weight: FontWeight.w600, color: AppColors.textTertiary)),
            const SizedBox(height: 6),
            Text(
              'Choose a goal from the sidebar,\nor press ⌘N to create one.',
              style: AppText.body(13, color: AppColors.textDisabled),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom title bar ──────────────────────────────────────────────────────────

class _TitleBar extends StatelessWidget {
  final VoidCallback onNewGoal;
  final VoidCallback onSettings;

  const _TitleBar({required this.onNewGoal, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 38,
        color: AppColors.sidebarBg,
        child: Row(
          children: [
            const SizedBox(width: 80), // Space for macOS traffic lights
            const Spacer(),
            Text('GoalKeeper',
                style: AppText.display(13,
                    weight: FontWeight.w600, color: AppColors.textSecondary)),
            const Spacer(),
            _titleBarButton(Icons.settings_rounded, onSettings,
                tooltip: 'Settings (⌘,)'),
            _titleBarButton(Icons.add_circle_rounded, onNewGoal,
                color: AppColors.accent, tooltip: 'New Goal (⌘N)'),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _titleBarButton(IconData icon, VoidCallback onTap,
      {Color? color, String? tooltip}) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }
}

// ── Resize handle ─────────────────────────────────────────────────────────────

class _ResizeHandle extends StatelessWidget {
  final void Function(double dx) onDrag;
  const _ResizeHandle({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(width: 1, color: AppColors.divider),
      ),
    );
  }
}
