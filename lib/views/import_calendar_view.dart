// lib/views/import_calendar_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:goalkeeper/store/goal_store.dart';
import 'package:goalkeeper/models/models.dart';
import 'package:goalkeeper/services/ics_parser.dart';
import 'package:goalkeeper/theme/app_theme.dart';

class ImportCalendarView extends StatefulWidget {
  const ImportCalendarView({super.key});
  @override
  State<ImportCalendarView> createState() => _ImportCalendarViewState();
}

class _ImportCalendarViewState extends State<ImportCalendarView> {
  int _tab = 0; // 0 = ICS, 1 = Manual

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.sidebarBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SizedBox(
        width: 520,
        height: 540,
        child: Column(
          children: [
            _header,
            const Divider(height: 1, color: AppColors.divider),
            _tabBar,
            Expanded(child: _tab == 0
                ? _ICSTab(onDone: () => Navigator.pop(context))
                : _ManualTab(onDone: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  Widget get _header => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Calendar', style: AppText.display(18, weight: FontWeight.w700)),
              Text('Import a .ics file or add an event manually.',
                  style: AppText.body(12, color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget get _tabBar => Row(children: [
        _tabItem('Import .ics', 0),
        _tabItem('Add Event', 1),
      ]);

  Widget _tabItem(String label, int idx) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = idx),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(label,
                  style: AppText.body(13,
                      weight: _tab == idx ? FontWeight.w600 : FontWeight.w400,
                      color: _tab == idx
                          ? AppColors.eventBlue
                          : AppColors.textSecondary)),
            ),
            Container(height: 2,
                color: _tab == idx ? AppColors.eventBlue : Colors.transparent),
          ]),
        ),
      );
}

// ── ICS Import Tab ─────────────────────────────────────────────────────────────

class _ICSTab extends StatefulWidget {
  final VoidCallback onDone;
  const _ICSTab({required this.onDone});
  @override
  State<_ICSTab> createState() => _ICSTabState();
}

class _ICSTabState extends State<_ICSTab> {
  List<CalendarEvent> _events = [];
  String _calName = '';
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (_events.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.eventBlue.withOpacity(0.2),
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(children: [
              Icon(Icons.calendar_month_rounded,
                  size: 48, color: AppColors.eventBlue.withOpacity(0.6)),
              const SizedBox(height: 14),
              Text(
                'Choose a .ics file from Google Calendar,\nApple Calendar, or your school portal.',
                style: AppText.body(13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loading ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.eventBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (_loading) ...[
                      const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black)),
                      const SizedBox(width: 8),
                      Text('Parsing…', style: AppText.body(14, weight: FontWeight.w600, color: Colors.black)),
                    ] else ...[
                      const Icon(Icons.upload_file_rounded, size: 14, color: Colors.black),
                      const SizedBox(width: 8),
                      Text('Choose .ics File…',
                          style: AppText.body(14, weight: FontWeight.w600, color: Colors.black)),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: AppText.body(12, color: AppColors.danger)),
          ],
        ] else ...[
          Row(children: [
            const Icon(Icons.calendar_month_rounded,
                size: 13, color: AppColors.eventBlue),
            const SizedBox(width: 6),
            Text(_calName.isEmpty ? 'Imported Calendar' : _calName,
                style: AppText.body(13, weight: FontWeight.w700, color: AppColors.eventBlue)),
            const Spacer(),
            Text('${_events.length} events',
                style: AppText.body(12, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          ..._events.take(10).map((e) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: e.color.color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.title,
                      style: AppText.body(12, weight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                  Text(
                    '${e.startDate.month}/${e.startDate.day}/${e.startDate.year}',
                    style: AppText.body(10, color: AppColors.textSecondary),
                  ),
                ]),
              )),
          if (_events.length > 10)
            Text('…and ${_events.length - 10} more',
                style: AppText.body(11, color: AppColors.textTertiary)),
          const SizedBox(height: 14),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() { _events = []; _calName = ''; }),
              child: Text('Start Over', style: AppText.body(13, color: AppColors.textSecondary)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                context.read<GoalStore>().addEvents(_events);
                widget.onDone();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.eventBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, size: 13, color: Colors.black),
                  const SizedBox(width: 6),
                  Text('Add ${_events.length} Events',
                      style: AppText.body(13, weight: FontWeight.w600, color: Colors.black)),
                ]),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await FilePicker.platform.pickFiles(
        allowedExtensions: ['ics'], type: FileType.custom);
      if (r != null && r.files.single.path != null) {
        final content = await File(r.files.single.path!).readAsString();
        final (events, name) = ICSParser.parse(content);
        setState(() { _events = events; _calName = name; });
      }
    } catch (e) {
      setState(() => _error = 'Could not read file: $e');
    }
    setState(() => _loading = false);
  }
}

// ── Manual Event Tab ───────────────────────────────────────────────────────────

class _ManualTab extends StatefulWidget {
  final VoidCallback onDone;
  const _ManualTab({required this.onDone});
  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _start  = DateTime.now();
  bool _hasEnd     = false;
  DateTime _end    = DateTime.now().add(const Duration(hours: 1));
  bool _allDay     = true;
  CalendarEventColor _color = CalendarEventColor.blue;

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _field('Title', TextField(
          controller: _titleCtrl,
          style: AppText.body(14),
          decoration: const InputDecoration(
            hintText: 'e.g. Finals Week, Field Trip…',
            border: InputBorder.none, contentPadding: EdgeInsets.zero),
          onChanged: (_) => setState(() {}),
        )),
        _field('Date', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Switch(value: _allDay, onChanged: (v) => setState(() => _allDay = v)),
            const SizedBox(width: 8),
            Text('All Day', style: AppText.body(13, color: AppColors.textSecondary)),
          ]),
          TextButton(
            onPressed: () async {
              final d = await showDatePicker(context: context,
                  initialDate: _start, firstDate: DateTime(2020),
                  lastDate: DateTime(2030));
              if (d != null) setState(() => _start = d);
            },
            child: Text('${_start.month}/${_start.day}/${_start.year}',
                style: AppText.body(13, color: AppColors.eventBlue)),
          ),
        ])),
        _field('Color', Row(children: CalendarEventColor.values.map((c) =>
            GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: c.color, shape: BoxShape.circle,
                  border: Border.all(
                    color: _color == c ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )).toList())),
        _field('Notes', TextField(
          controller: _notesCtrl,
          style: AppText.body(13),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Any extra details…',
            border: InputBorder.none, contentPadding: EdgeInsets.zero),
        )),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _valid ? _save : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _valid ? AppColors.eventBlue : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_circle_rounded, size: 14, color: Colors.black),
              const SizedBox(width: 8),
              Text('Add Event',
                  style: AppText.body(14, weight: FontWeight.w600, color: Colors.black)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _field(String label, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: AppText.label(9)),
          const SizedBox(height: 5),
          child,
        ]),
      );

  void _save() {
    context.read<GoalStore>().addEvent(CalendarEvent(
      title: _titleCtrl.text, notes: _notesCtrl.text,
      startDate: _start, endDate: _hasEnd ? _end : null,
      isAllDay: _allDay, color: _color, source: CalendarEventSource.manual,
    ));
    widget.onDone();
  }
}
