// lib/views/main_scaffold.dart
// 3-column layout — equivalent to ContentView.swift NavigationSplitView

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:goalkeeper/models/models.dart';
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
  static const _appShortcutsChannel = MethodChannel('goalkeeper/app_shortcuts');

  double _sidebarWidth = 250;
  double _calendarWidth = 370;
  bool _settingsOpen = false;
  static const double _minSidebarWidth = 200;
  static const double _maxSidebarWidth = 300;
  static const double _minCalendarWidth = 300;
  static const double _maxCalendarWidth = 440;

  @override
  void initState() {
    super.initState();
    _appShortcutsChannel.setMethodCallHandler(_handleAppShortcut);
  }

  @override
  void dispose() {
    _appShortcutsChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleAppShortcut(MethodCall call) async {
    switch (call.method) {
      case 'openSettings':
        if (mounted) _showSettings();
        return;
      default:
        throw MissingPluginException('Unknown app shortcut: ${call.method}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.comma, meta: true):
            _OpenSettingsIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): _NewGoalIntent(),
      },
      child: Actions(
        actions: {
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              _showSettings();
              return null;
            },
          ),
          _NewGoalIntent: CallbackAction<_NewGoalIntent>(
            onInvoke: (_) {
              _showAddGoal();
              return null;
            },
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
                          onAddGoal: _showAddGoal,
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
    if (_settingsOpen) return;
    _settingsOpen = true;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GoalStore>(),
        child: const SettingsView(),
      ),
    ).whenComplete(() => _settingsOpen = false);
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

class _TitleBar extends StatefulWidget {
  final VoidCallback onNewGoal;
  final VoidCallback onSettings;

  const _TitleBar({required this.onNewGoal, required this.onSettings});

  @override
  State<_TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<_TitleBar> {
  final _quickGoalCtrl = TextEditingController();

  @override
  void dispose() {
    _quickGoalCtrl.dispose();
    super.dispose();
  }

  void _submitQuickGoal() {
    final title = _quickGoalCtrl.text.trim();
    if (title.isEmpty) return;

    context.read<GoalStore>().addGoal(Goal(
          title: title,
          description: '',
          type: GoalType.personalGoal,
          priority: GoalPriority.medium,
        ));
    _quickGoalCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 38,
        color: AppColors.sidebarBg,
        child: Row(
          children: [
            const SizedBox(width: 80), // Space for macOS traffic lights
            Expanded(child: Center(child: _quickGoalBar)),
            _titleBarButton(Icons.settings_rounded, widget.onSettings,
                tooltip: 'Settings (⌘,)'),
            _titleBarButton(Icons.add_circle_rounded, widget.onNewGoal,
                color: AppColors.accent, tooltip: 'New Goal (⌘N)'),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget get _quickGoalBar {
    final hasText = _quickGoalCtrl.text.trim().isNotEmpty;

    return Container(
      width: 430,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 9),
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
          const SizedBox(width: 7),
          Expanded(
            child: TextField(
              controller: _quickGoalCtrl,
              textInputAction: TextInputAction.done,
              style: AppText.body(12, color: AppColors.textPrimary),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Quick Goal',
                hintStyle: AppText.body(12, color: AppColors.textTertiary),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submitQuickGoal(),
            ),
          ),
          Tooltip(
            message: 'Add quick goal',
            child: InkWell(
              onTap: hasText ? _submitQuickGoal : null,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 14,
                  color: hasText ? AppColors.accent : AppColors.textDisabled,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
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
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(width: 1, color: AppColors.divider),
      ),
    );
  }
}
